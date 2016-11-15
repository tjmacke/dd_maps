#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -a addr-file -at { src | dst } [ -cnt ] [ -rev ] [ -unit { day | week | month } ] [ -stats stats-file ] [ runs-file ]"

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
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	READ_ADDRESSES="\"$DM_LIB/read_addresses.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

AFILE=
ATYPE==
CNT=
REV=
UNIT=
SFILE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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
	-cnt)
		CNT="yes"
		shift
		;;
	-rev)
		REV="yes"
		shift
		;;
	-unit)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-unit requires unit argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		UNIT=$1
		shift
		;;
	-stats)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-stats requires stats-file argument"
			echo "$U_MSG"
			exit 1
		fi
		SFILE=$1
		shift
		;;
	-*)
		LOG ERROR "unknown argument $1"
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

if [ ! -z "$UNIT" ] ; then
	if [ "$UNIT" != "day" ] && [ "$UNIT" != "week" ] && [ "$UNIT" != "month" ] ; then
		LOG ERROR "unknown unit $UNIT, must be day, week, month"
		echo "$U_MSG" 1>&2
		exit 1
	fi
fi

$AWK -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_atype = atype == "src" ? 6 : 7
}
$5 == "Job" {
	printf("%s\t%s\n", $1, $f_atype)
}' $FILE	|\
sort -t $'\t' -k 2,2 -k 1,1	|\
$AWK -F'\t' '
@include '"$READ_ADDRESSES"'
BEGIN {
	afile = "'"$AFILE"'"
	n_a2idx = read_addresses(afile, a2idx, alng, alat)
}
{
	if($2 != l_2){
		if(l_2 != ""){
			printf("%s\t%d\t%s\t%s\t%s\n", date, cnt, l_2,  alng[a2idx[l_2]], alat[a2idx[l_2]]) 
			l_2 = ""
			cnt = 0
		}
	}
	if(!($2 in a2idx)){
		printf("WARN: address %s not in %s\n", $2, afile) > "/dev/stderr"
		next
	}
	cnt++
	date = $1
	l_2 = $2 
}
END {
	if(l_2 != ""){
		printf("%s\t%d\t%s\t%s\t%s\n", date, cnt, l_2,  alng[a2idx[l_2]], alat[a2idx[l_2]]) 
		l_2 = ""
		cnt = 0
	}
}'		|\
$AWK -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	cnt = "'"$CNT"'" == "yes"
	rev = "'"$REV"'" == "yes"
	unit = "'"$UNIT"'"
	if(unit == "")
		unit = 1
	else if(unit == "day")
		unit = 86400
	else if(unit == "week")
		unit = 7 * 86400
	else if(unit == "month")
		unit = 30 * 86400
	else{
		printf("ERROR: unknown unit: %s\n", unit) > "/dev/stderr"
		err = 1
		exit err
	}
	sfile = "'"$SFILE"'"
}
{
	n_addrs++
	dates[n_addrs] = $1
	cnts[n_addrs] = $2
	tcnt += $2
	addrs[n_addrs] = $3
	lngs[n_addrs] = $4
	lats[n_addrs] = $5
}
END {
	if(err)
		exit err

	# TODO: deal with !rev
	if(rev){
		date_max = dates[1]
		date_min = dates[1]
		for(i = 2; i <= n_addrs; i++){
			if(dates[i] < date_min)
				date_min = dates[i]
			else if(dates[i] > date_max)
				date_max = dates[i]
		}
		work = date_max
		gsub(/-/, " ", work)
		t_max = mktime(work " 00 00 00")
	}
	for(i = 1; i <= n_addrs; i++){
		work = dates[i]
		gsub(/-/, " ", work)
		t = mktime(work " 00 00 00")
		t = rev ? t_max - t : t
		t /= unit
		if(unit == 1)
			printf("%d", t)
		else
			printf("%g", t)
		if(cnt){
			label = sprintf("visits=%d, last=%s", cnts[i], dates[i])
			printf("\t%d\t%s", cnts[i], label)
		}else{
			label = sprintf("last=%s", dates[i])
			printf("\t%s", label)
		}
		printf("\t%s\t%s\t%s\n", addrs[i], lngs[i], lats[i])
	}
	if(sfile){
		# stats to json is stupid
		printf("data_stats = %d %s&#44; %d dashes&#44; last &#61; %s\n", NR, atype == "src" ? "sources" : "dests", tcnt, rev ? date_max : date_min) >> sfile
		close(sfile)
	}
}'
