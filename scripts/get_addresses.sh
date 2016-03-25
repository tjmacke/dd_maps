#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -c conf-file ] -at { src | dst } [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	RD_CONFIG="$DM_LIB/rd_config.awk"
	PARSE_ADDRESS="$DM_LIB/parse_address.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	RD_CONFIG="\"$DM_LIB/rd_config.awk\""
	PARSE_ADDRESS="\"$DM_LIB/parse_address.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

CFILE=$DM_ETC/address.info
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-c)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-c requires conf-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		CFILE=$1
		shift
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

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unkonwn address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

$AWK -F'\t' '
@include '"$RD_CONFIG"'
@include '"$PARSE_ADDRESS"'
BEGIN {
	atype = "'"$ATYPE"'"
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

	pr_hdr = 1
}
$5 == "Job" {
	date = $1
	src = $6
	dst = $7

	parse_address(atype == "src" ? src : dst, result, dirs, st_abbrevs, st_quals, towns)
	if(pr_hdr){
		pr_hdr = 0
		if(atype == "src")
			printf("status\tdate\tsrc\tdst\tqSrc\tsName\n")
		else
			printf("status\tdate\tsrc\tdst\tqDst\tdName\n")
	}
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
