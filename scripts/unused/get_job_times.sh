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

awk -F'\t' 'BEGIN { prheader=1 }
$5=="Job" {
	if($2 == ".")
		next
	if($3 == ".")
		next
	j_date = $1
	gsub(/-/," ",j_date)
	j_start = $2
	gsub(/:/," ",j_start)
	j_end = $3
	gsub(/:/," ",j_end)

	t_start = mktime(j_date " " j_start " 00")
	t_end = mktime(j_date " " j_end " 00")
	minutes = t_end - t_start

	if(prheader){
		prheader=0
		printf("date\tt_start\tt_end\tminutes\n")
	}
	printf("%s\t%s\t%s\t%.2f\n", $1, $2, $3 , 1.0*minutes/60)
}' $FILE
