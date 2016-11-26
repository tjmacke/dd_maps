#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -d dashes-file -a addr-file -at { src | dst } [ -stats stats-file ] [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support includes
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	READ_ADDRESSES="$DM_LIB/read_addresses.awk"
	DASH_UTILS="$DM_LIB/dash_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	READ_ADDRESSES="\"$DM_LIB/read_addresses.awk\""
	DASH_UTILS="\"$DM_LIB/dash_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

DFILE=
AFILE=
ATYPE=
SFILE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-d)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-d requires dashes-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DFILE=$1
		shift
		;;
	-a)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-a requires addr-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		AFILE=$1
		shift
		;;
	-at)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-at requires address-type argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		ATYPE=$1
		shift
		;;
	-stats)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-stats requires stats-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		SFILE=$1
		shift
		;;
	-*)
		LOG ERROR "unknown option $1"
		echo "$U_MSG" 1>&2
		exit 1
		;;
	*)
		FILE=$1
		shift
		break
		;;
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DFILE" ] ; then
	LOG ERROR "missing -d dashes-file argument"
	echo "$U_UMSG" 1>&2
	exit 1
fi

if [ -z "$AFILE" ] ; then
	LOG ERROR "missing -a addr-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_atype = atype == "src" ? 6 : 7
}
$5 == "Job" {
	printf("%s\t%s\t%s\t%s\n", $1, $2, $3, $f_atype)
}' $FILE	|\
sort -t $'\t' -k 4,4 -k 1,1 -k 2,2	|\
$AWK -F'\t' '
@include '"$READ_ADDRESSES"'
@include '"$DASH_UTILS"'
BEGIN {
	atype = "'"$ATYPE"'"
	afield = atype == "src" ? 6 : 7

	# read the addresses
	afile = "'"$AFILE"'"
	n_a2idx = read_addresses(afile, a2idx, alng, alat)
	if(n_a2idx == 0){
		printf("ERROR: no addresses in %s\n", afile) > "/dev/stderr"
		err = 1
		exit err
	}
#	printf("INFO: %s: %d addresses\n", afile, n_a2idx) > "/dev/stderr"

	# read pay breakdown data
	dfile = "'"$DFILE"'"
	n_dashes_keys = DU_read_dashes(dfile, dashes_keys, dashes_vals, dashes_fields, dashes_sizes)
	if(n_dashes_keys == 0){
		printf("ERROR: dashes file %s has no data\n", dfile)
		err = 1
		exit err
	}
#	printf("INFO: %s: %d records\n", dfile, n_dashes_keys) > "/dev/stderr"

	sfile = "'"$SFILE"'"
}
{
	if($4 != l_4){
		if(l_4 != ""){
			if(get_drate(l_4, n_visits, visits, results)){
				if(!(l_4 in a2idx)){
					printf("WARN: no geo for %s\n", l_4) > "/dev/stderr"
				}else{
					label = sprintf("visits=%d, last=%s, avgPay=%.2f", results["d_cnt"], results["d_last"], results["d_rate"])
					idx = a2idx[l_4]
					printf("%.2f\t%d\t%s\t%s\t%s\t%s\n", results["d_rate"], results["d_cnt"], label, l_4, alng[idx], alat[idx])
					n_dashes += results["d_cnt"]
					n_sites++
					if(date_max == "")
						date_max = visits[1, "Date"]
					else if(visits[1, "Date"] > date_max)
						date_max = visits[1, "Date"]
				}
			}
			delete results
			n_visits = 0
			delete visits
		}
	}
	n_visits++
	visits[n_visits, "Date"] = $1
	visits[n_visits, "tStart"] = $2
	visits[n_visits, "tEnd"] = $3
	l_4 = $4
}
END {
	if(err)
		exit err

	if(l_4 != ""){
		if(get_drate(l_4, n_visits, visits, results)){
			if(!(l_4 in a2idx)){
				printf("WARN: no geo for %s\n", l_4) > "/dev/stderr"
			}else{
				label = sprintf("visits=%d, last=%s, avgPay=%.2f", results["d_cnt"], results["d_last"], results["d_rate"])
				idx = a2idx[l_4]
				printf("%.2f\t%d\t%s\t%s\t%s\t%s\n", results["d_rate"], results["d_cnt"], label, l_4, alng[idx], alat[idx])
				n_dashes += results["d_cnt"]
				n_sites++
				if(date_max == "")
					date_max = visits[1, "Date"]
				else if(visits[1, "Date"] > date_max)
					date_max = visits[1, "Date"]
			}
		}
		delete results
		n_visits = 0
		delete visits
	}

	if(sfile){
		# stats to json is stupid
		printf("data_stats = %d %s&#44; %d dashes&#44; last &#61; %s\n", n_sites, atype == "src" ? "sources" : "dests", n_dashes, date_max) >> sfile
		close(sfile)
	}
}
function get_drate(site, n_visits, visits, results,   i, k_idx, fnd, j, ary, nf, d_cnt, d_amt, d_last) {

	d_cnt = d_amt = 0
	for(i = 1; i <= n_visits; i++){
		if(!DU_find_dash_cands(visits[i, "Date"], n_dashes_keys, dashes_keys, k_idx)){
			printf("WARN: no pay breakdown data for date %s\n", visits[i, "Date"]) > "/dev/stderr"
			continue
		}
		fnd = 0
		for(j = k_idx["start"]; j <= k_idx["end"]; j++){
			nf = split(dashes_vals[j], ary, "\t")
			if(DU_job_in_dash(visits[i, "tStart"], visits[i, "tEnd"], ary[dashes_fields["tstart"]], ary[dashes_fields["tend"]])){
				fnd = 1
				d_cnt++
				d_amt += ary[dashes_fields["totalpay"]]/ary[dashes_fields["deliveries"]]
				d_last = visits[i, "Date"]
				break
			}
		}
		if(!fnd){
			printf("WARN: no pay breakdown data for dash = %s, %s, %s\n",
				visits[i, "Date"], visits[i, "sTime"], visits[i, "eTime"]) > "/dev/stderr"
		}
	}
	if(d_cnt == 0){
		printf("WARN: no pay breakdown data for site %s\n", site) > "/dev/stderr"
		return 0
	}

	results["d_rate"] = d_amt/d_cnt
	results["d_cnt"] = d_cnt
	results["d_last"] = d_last
	
	return 1
}' $FILE
