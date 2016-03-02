#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ summary-file ]"

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
	LOG ERROR "extra argumnents $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	pr_hdr = 1
}
NR > 1 {
	t = mktime(sprintf("%s %s %s 12 00 00", substr($1, 1, 4), substr($1, 6, 2), substr($1, 9, 10)))
	n_dow = strftime("%w", t)
	if(n_dow == 1)
		monday = $1
	else if(n_dow > 1){
		monday = strftime("%Y-%m-%d", t - (n_dow - 1) * 86400)
	}else{
		monday = strftime("%Y-%m-%d", t - 6 * 86400)
	}
	if(c_monday == ""){
		c_monday = monday
	}else if(monday != c_monday){
		if(pr_hdr){
			pr_hdr = 0
			printf("date\thours\n")
		}
		printf("%s\t%.2f\n", c_monday, hours)
		hours = 0
		c_monday = monday
	}
	hours += $2
}
END {
	if(c_monday != ""){
		if(pr_hdr){
			pr_hdr = 0
			print("date\thours\n")
		}	
		printf("%s\t%.2f\n", c_monday, hours)
	}
}' $FILE
