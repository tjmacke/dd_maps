#! /bin/bash
#
. ~/etc/funcs.sh

export LC_ALL=C

U_MSG="usage: $0 [ -help ] -a addr-file [ -cnt ] [ dates-file ]"

AFILE=
CNT=
FILE=$1

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
	-cnt)
		CNT="yes"
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

sort -t $'\t' -k 2,2 -k 1,1 $FILE	|\
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
}' |\
awk -F'\t' 'BEGIN {
	cnt = "'"$CNT"'" == "yes"
}
{
	work = $1
	gsub(/-/, " ", work)
	t = mktime(work " 00 00 00")
	if(cnt){
		label = sprintf("visits=%d, last=%s", $2, $1)
		printf("%d\t%s\t%s\t%s\t%s\t%s\n", t, $2, label, $3, $4, $5)
	}else{
		label = sprintf("last=%s", $1)
		printf("%d\t%s\t%s\t%s\t%s\n", t, label, $3, $4, $5)
	}
}'
