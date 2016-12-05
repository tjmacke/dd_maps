#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] geo-error-file"

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

if [ -z "$FILE" ] ; then
	LOG ERROR "missing geo-error-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk 'BEGIN {
	pr_hdr = 1
}
{
	if(substr($1, 1, 5) == "ERROR"){
		if(errInfo["addr"] != ""){
			if(pr_hdr){
				pr_hdr = 0
				printf("%s\t%s\t%s\t%s\t%s\n", "error", "date", "origDst", "queryDst", "replyDst")
			}
			fmt_errInfo(errInfo)
			delete errInfo
		}
		nf = split($0, ary, ":")
		for(i = 1; i <= nf; i++){
			sub(/^[ \t][ \t]*/, "", ary[i])
			sub(/[ \t][ \t]*$/, "", ary[i])
		}
		errInfo["date"] = ary[2]
		errInfo["addr"] = ary[4]
		errInfo["emsg"] = ary[5]
	}else if($1 == "{"){
		in_details = 1
	}else if($1 == "}"){
		in_details = 0
	}else if(in_details){
		nf = split($0, ary, "=")
		for(i = 1; i <= nf; i++){
			sub(/^[ \t][ \t]*/, "", ary[i])
			sub(/[ \t][ \t]*$/, "", ary[i])
		}
		errInfo[ary[1]] = ary[2]
	}
}
END {
	if(errInfo["addr"] != "")
		if(pr_hdr){
			pr_hdr = 0
			printf("%s\t%s\t%s\t%s\t%s\n", "error", "date", "origDst", "queryDst", "replyDst")
		}
		fmt_errInfo(errInfo)
}
function fmt_errInfo(errInfo) {
	printf("%s", errInfo["emsg"])
	printf("\t%s", errInfo["date"])
	printf("\t%s", errInfo["addr"])
	printf("\t%s", "query" in errInfo ? errInfo["query"] : "")
	printf("\t%s", "reply" in errInfo ? errInfo["reply"] : "")
	printf("\n")
}' $FILE
