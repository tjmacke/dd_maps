#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -a addr-file -at { src | dst } [ -cnt ] [ -rev ] [ -unit { day | week | month } ] [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi

DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

AFILE=
ATYPE==
CNT=
REV=
UNIT=
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

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_atype = atype == "src" ? 6 : 7
}
$5 == "Job" {
	printf("%s\t%s\n", $1, $f_atype)
}' $FILE	|\
sort -t $'\t' -k 2,2 -k 1,1	|\
awk -F'\t' 'BEGIN {
	afile = "'"$AFILE"'"
	for(n_a2idx = 0; (getline < afile) > 0; ){
		n_a2idx++
		a2idx[$1] = n_a2idx
		long[n_a2idx] = $2
		lat[n_a2idx] = $3
	}
	close(afile)
}
{
	if($2 != l_2){
		if(l_2 != ""){
			printf("%s\t%d\t%s\t%s\t%s\n", date, cnt, l_2,  long[a2idx[l_2]], lat[a2idx[l_2]]) 
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
		printf("%s\t%d\t%s\t%s\t%s\n", date, cnt, l_2,  long[a2idx[l_2]], lat[a2idx[l_2]]) 
		l_2 = ""
		cnt = 0
	}
}'		|\
awk -F'\t' 'BEGIN {
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
}
{
	n_addrs++
	dates[n_addrs] = $1
	cnts[n_addrs] = $2
	addrs[n_addrs] = $3
	lngs[n_addrs] = $4
	lats[n_addrs] = $5
}
END {
	if(err)
		exit err

	if(rev){
		date_max = dates[1]
		for(i = 2; i <= n_addrs; i++){
			if(dates[i] > date_max)
				date_max = dates[i]
		}
		gsub(/-/, " ", date_max)
		t_max = mktime(date_max " 00 00 00")
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
}'
