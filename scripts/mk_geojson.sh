#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ resolved-address-file ]"

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
	need_nl = 0
}
{
	if(pr_hdr){
		pr_hdr = 0
		printf("[\n")
	}
	if(need_nl){
		need_nl = 0
		printf(",\n")
	}
	printf("{ ")
	printf("\"type\": \"Feature\", ")
	printf("\"geometry\": { ")
	printf("\"type\": \"Point\", ")
	printf("\"coordinates\": [%s, %s]", $5, $4)
	printf(" }, ")
	printf("\"properties\": { ")
	printf("\"date\": \"%s\", ", $1)
	printf("\"title\": \"src: %s\\ndst: %s\", ", $2, $3)
	printf("\"marker-color\": \"#b33\"")
	printf(" }")
	printf(" }")
	need_nl = 1
}
END {
	if(!pr_hdr){
		if(need_nl){
			need_nl = 0
			printf("\n")
		}
		printf("]\n")
	}
}' $FILE
