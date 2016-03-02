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

awk -F'\t' 'NR > 1 { 
	t_weeks++
	t_days++
	t_hours += $2
	t_miles += $3
	t_jobs += $4
	t_amt += $5
}
END {
	if(t_weeks > 0){
		printf("%s\t%s\t%s\t%s\t%s\n", "days", "hours", "miles", "jobs", "amount")
		printf("%d\t%.2f\t%d\t%d\t%.2f\n", t_days, t_hours, t_miles, t_jobs, t_amt)
	}
}' $FILE
