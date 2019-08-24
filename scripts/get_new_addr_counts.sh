#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } db-file"

ATYPE=
DB=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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
		DB=$1
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

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unkonwn address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DB" ] ; then
	LOG ERROR "missing db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

sqlite3 $DB <<_EOF_ |
.mode tabs
PRAGMA foreign_keys = ON ;
SELECT time_start, payment, $ATYPE.address 
FROM jobs
INNER JOIN addresses AS $ATYPE ON $ATYPE.address_id = ${ATYPE}_addr_id
ORDER BY time_start ;
_EOF_
awk -F'\t' 'BEGIN {
	k_apps["ALL"] = 1
	n_apps = 1;
	apps[n_apps] = "ALL"
}
{
	# known apps
	if(!($2 in k_apps)){
		k_apps[$2] = 1
		n_apps++
		apps[n_apps] = $2
	}
	# find known app|address pairs
	aa = $2 "|" $3
	if(!(aa in k_aa_pairs)){
		k_aa_pairs[aa] = 1
		n_aa_pairs++
		aa_pairs[n_aa_pairs] = aa
		first[n_aa_pairs] = $1
	}
}
END {
	for(j = 1; j <= n_apps; j++)
		app_counts[apps[j]] = 0
	for(i = 1; i <= n_aa_pairs; i++){
		n_ary = split(aa_pairs[i], ary, "|")
		if(!(ary[2] in all_addrs)){
			all_addrs[ary[2]] = 1
			app_counts["ALL"]++
		}
		app_counts[ary[1]]++
		out["date", i] = first[i]
		for(j = 1; j <= n_apps; j++)
			out[apps[j], i] = app_counts[apps[j]]
	}
	for(j = 2; j <= n_apps; j++){
		for(i = n_aa_pairs; i > 1; i--){
			if(out[apps[j], i] == out[apps[j], i-1])
				out[apps[j], i] = -1
			else
				break
		}
	}

	printf("date")
	for(i = 1; i <= n_apps; i++)
		printf("\t%s", apps[i])
	printf("\n")
	# check if 1st date is 1st of month, if not add YYYY-mm-01 -1 ...
	if(out["date", 1] !~ /01$/){
		printf("%s-01", substr(out["date", 1], 1, 7))
		for(j = 1; j <= n_apps; j++)
			printf("\t-1")
		printf("\n")
	}
	for(i = 1; i <= n_aa_pairs; i++){
		printf("%s", out["date", i])
		for(j = 1; j <= n_apps; j++)
			printf("\t%s", out[apps[j], i])
		printf("\n")
	}
	# chexk if last date is 1st of month, if not add 1st of next month -1 ...
	if(out["date", n_aa_pairs] !~ /01$/){
		n_ary = split(out["date", n_aa_pairs], ary, "-")
		for(i = 1; i <= n_ary; i++)
			ary[i] += 0
		if(ary[2] < 12)
			ary[2]++
		else{
			ary[1]++
			ary[2] = 1
		}
		printf("%04d-%02d-01", ary[1], ary[2])
		for(j = 1; j <= n_apps; j++)
			printf("\t-1")
		printf("\n")
	}
}'	|
awk -F'\t' 'NR == 1 {
	printf("%s\n", $0)
	next
}
{
	date = substr($1, 1, 10) 
	if(date != l_date){
		if(l_date != ""){
			n_ary = split(last, ary, "\t")
			printf("%s", l_date)
			for(i = 2; i <= n_ary; i++) 
				printf("\t%s", ary[i])
			printf("\n")
		}
	}
	last = $0
	l_date = date
}
END {
	if(l_date != ""){
		n_ary = split(last, ary, "\t")
		printf("%s", l_date)
		for(i = 2; i <= n_ary; i++) 
			printf("\t%s", ary[i])
		printf("\n")
	}
}'
