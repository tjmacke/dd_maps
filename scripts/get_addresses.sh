#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -b ] [ runs-file ]"

CFILE=$DM_HOME/etc/address.info
FILE=
BOPT=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-b)
		BOPT="yes"
		shift
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

awk -F'\t' '
@include "'"$DM_HOME"'/lib/rd_config.awk"
@include "'"$DM_HOME"'/lib/parse_address.awk"
BEGIN {
	cfile = "'"$CFILE"'"
	if(rd_config(cfile, config)){
		err = 1
		exit err
	}
	for(k in config){
		split(k, keys, SUBSEP)
		if(keys[1] == "dirs")
			dirs[keys[2]] = config[k]
		else if(keys[1] == "st_abbrevs")
			st_abbrevs[keys[2]] = config[k]
		else if(keys[1] == "st_quals")
			st_quals[keys[2]] = config[k]
		else if(keys[1] == "towns")
			towns[keys[2]] = config[k]
		else{
			printf("ERROR: unknown table %s in config file %s\n", keys[1], cfile) > "/dev/stderr"
			err = 1 
			exit 1
		}
	}

	bopt = "'"$BOPT"'" == "yes"
	printf("status\tdate\tsrc\tdst\tqDst\tdName\n")
}
$5 == "Job" {
	date = $1
	src = $6
	dst = $7

	parse_address(dst, result, dirs, st_abbrevs, st_quals, towns)
	printf("%s", result["status"])
	if(result["status"] == "B")
		printf(", %s", result["emsg"])
	printf("\t%s\t%s\t%s", date, src, dst)
	if(result["status"] == "B")
		printf("\t\t")
	else
		printf("\t%s, %s, %s\t%s", result["street"], result["town"], result["state"], result["name"])
	printf("\n")

}' $FILE
