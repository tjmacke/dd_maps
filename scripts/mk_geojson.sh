#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ resolved-address-file ]"

NOW=
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
	R_min = 0.933 ; G_min = 0.867 ; B_min = 0.867
	R_max = 0.933 ; G_max = 0.133 ; G_max = 0.133
	R_range = R_max - R_min
	G_range = G_max - G_min
	B_range = B_max - B_min
}
{
	n_dashes++
	date[n_dashes] = $1
	if(min_date == "")
		min_date = $1
	else if($1 < min_date)
		min_date = $1
	if(max_date == "")
		max_date = $1
	else if($1 > max_date)
		max_date = $1
	src[n_dashes] = $2
	dst[n_dashes] = $3
	lat[n_dashes] = $4
	lng[n_dashes] = $5
}
END {
	work = min_date
	gsub(/-/, " ", work)
	t_min = mktime(work " 00 00 00")

	work = max_date
	gsub(/-/, " ", work)
	t_max = mktime(work " 00 00 00")
	
	for(d = 1; d <= n_dashes; d++){
		if(d == 1)
			printf("[\n")
		printf("{ ")
		printf("\"type\": \"Feature\", ")
		printf("\"geometry\": { ")
		printf("\"type\": \"Point\", ")
		printf("\"coordinates\": [%s, %s]", lng[d]5, lat[d])
		printf(" }, ")
		printf("\"properties\": { ")
		printf("\"date\": \"%s\", ", date[d])
		printf("\"title\": \"src: %s\\ndst: %s\\ndate: %s\", ", src[d], dst[d], date[d])
		color = set_color(date[d], t_min, t_max)
		printf("\"marker-color\": \"#%s\"", color)
		printf(" }")
		printf(" }%s\n", d < n_dashes ? "," : "")

		if(d == n_dashes)
			printf("]\n")
	}
}
function set_color(date, t_min, t_max,   work, t_range, t_diff, f, R, G, B) {
	work = date
	gsub(/-/, " ", work)
	t_range = t_max - t_min
	t_diff = mktime(work " 00 00 00") - t_min
	f = 1.0*t_diff/t_range
	R = int((R_min + f * R_range)/(1.0/15) + 0.5)
	G = int((G_min + f * G_range)/(1.0/15) + 0.5)
	B = int((B_min + f * B_range)/(1.0/15) + 0.5)
	return sprintf("%x%x%x", R, G, B)
}' $FILE
