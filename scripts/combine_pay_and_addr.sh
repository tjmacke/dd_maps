#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -dh doordash-home ] -a addr-file -at { src | dst } [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support includes
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	READ_ADDRESSES="$DM_LIB/read_addresses.awk"
	PB_UTILS="$DM_LIB/pb_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	READ_ADDRESSES="\"$DM_LIB/read_addresses.awk\""
	PB_UTILS="\"$DM_LIB/pb_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

AFILE=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-dh)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-dh requires doordash-hom argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DD_HOME=$1
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

if [ -z "$DD_HOME" ] ; then
	LOG ERROR "DD_HOME is not defined"
	echo "$U_MSG" 1>&2
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

$AWK -F'\t' '
@include '"$READ_ADDRESSES"'
@include '"$PB_UTILS"'
BEGIN {
	atype = "'"$ATYPE"'"
	afield = atype == "src" ? 6 : 7
	if(atype == "src"){
		afield = 6
		afile = "'"$DD_HOME"'/maps/src.addrs"
	}else{
		afield = 7
		afile = "'"$DD_HOME"'/maps/dst.addrs"
	}

	# read the addresses
	afile = "'"$AFILE"'"
	n_a2idx = read_addresses(afile, a2idx, alng, alat)
	if(n_a2idx == 0){
		printf("ERROR: no addresses in %s\n", afile) > "/dev/stderr"
		err = 1
		exit err
	}
	printf("INFO: %s: %d %s addresses\n", afile, n_a2idx, atype) > "/dev/stderr"

	# read pay breakdown data
	pb_file = "'"$DD_HOME"'/data/breakdownofpay.20150904.tsv"
	n_pb_keys = read_pay_breakdown(pb_file, pb_keys, pb_vals, pb_fields, pb_sizes)
	if(n_pb_keys == 0){
		printf("ERROR: pay breakdown file %s has no data\n", pb_file)
		err = 1
		exit err
	}
	printf("INFO: %s: %d pay breakdown entries\n", pb_file, n_pb_keys) > "/dev/stderr"
#	printf("pb_fields:\n")
#	for(f in pb_fields)
#		printf("%-12s -> %2d\n", f, pb_fields[f]) 
}
{
	if($5 == "BEGIN"){
		in_rec = 1
		date = $1
		b_time = $2
	}else if($5 == "END"){
		in_rec = 0
		e_time = $3
		if(!find_pay_data(date, n_pb_keys, pb_keys, k_idx)){
			printf("WARN: no pay breakdown data for date %s\n", date)
			err = 1
			next
		}
		fnd = 0
		for(i = k_idx["start"]; i <= k_idx["end"]; i++){
			nf = split(pb_vals[i], ary, "\t")
			if(pb_dashes_overlap(b_time, e_time, ary[pb_fields["tstart"]], ary[pb_fields["tend"]])){
				fnd = 1
#				drate = ary[pb_fields["drate"]]
				drate = ary[pb_fields["totalpay"]]/ary[pb_fields["deliveries"]]
				break
			}
		}
		if(!fnd){
			printf("ERROR: no pay breakdown date for date, start, end = %s, %s, %s\n", date, b_time, e_time) > "/dev/stderr"
		}else{
			for(j in jobs){
				j_amount[j] += drate
				j_count[j]++
			}
			delete jobs
			n_jobs = 0
		}
	}else if(in_rec){
		n_jobs++
		jobs[$afield] = 1
	}
}
END {
	if(err)
		exit err

	for(j in j_amount){
		if(!(j in a2idx)){
			printf("WARN: no geo for %s\n", j) > "/dev/stderr"
			continue
		}
		label = sprintf("visits=%d, avgPay=%.2f", j_count[j], j_amount[j]/j_count[j])
		idx = a2idx[j]
		printf("%.2f\t%d\t%s\t%s\t%s\t%s\n", j_amount[j]/j_count[j], j_count[j], label, j, alng[idx], alat[idx])
	}
}' $FILE
