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
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	pr_hdr = 1
}
{
	if($5 == "Job"){
		if(!($1 in dates))
			n_dates++
		dates[$1]++
		if(!($6 in sources))
			n_sources++
		sources[$6]++
	}else if($5 == "END"){
		if(pr_hdr){
			pr_hdr = 0
			printf("date\tnDashes\tnSources\tnNewSources\n")
		}
		printf("%s\t%d\t%d\t%d\n", $1, n_dates, n_sources, n_sources - l_ns)
		l_ns = n_sources
	}
}' $FILE
