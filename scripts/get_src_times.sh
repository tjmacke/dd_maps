#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ runs-file ]"

FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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
	echo "$U_MSG"
	exit 1
fi

awk -F'\t' '$5 == "Job" {
	printf("%s\t%sT%s:00\n", $6, $1, $2)
}' $FILE	|\
sort -t $'\t' -k 1,1 -k 2,2	|\
awk -F'\t' '{
	if($1 != l_1){
		if(l_1 != ""){
			printf("%s\t%d\t%s", l_1, n_times, times[1])
			for(i = 2; i <= n_times; i++)
				printf(" %s", times[i])
			printf("\n")
			delete times
			n_times = 0
		}
	}
	n_times++
	times[n_times] = $2
	l_1 = $1
}
END {
	if(l_1 != ""){
		printf("%s\t%d\t%s", l_1, n_times, times[1])
		for(i = 2; i <= n_times; i++)
			printf(" %s", times[i])
		printf("\n")
		delete times
		n_times = 0
	}
}'	|\
sort -t $'\t' -k 2rn,2 -k 1,1
