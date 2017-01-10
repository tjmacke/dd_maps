#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -c addr-info-file ] -at { src | dst } [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	CFG_UTILS="$DM_LIB/cfg_utils.awk"
	ADDR_UTILS="$DM_LIB/addr_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	CFG_UTILS="\"$DM_LIB/cfg_utils.awk\""
	ADDR_UTILS="\"$DM_LIB/addr_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

AI_FILE=$DM_ETC/address.info
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
			LOG ERROR "-c requires addr-info-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		AI_FILE=$1
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
@include '"$CFG_UTILS"'
@include '"$ADDR_UTILS"'
BEGIN {
	atype = "'"$ATYPE"'"

	ai_file = "'"$AI_FILE"'"
	if(CFG_read(ai_file, addr_info)){
		err = 1
		exit err
	}

	n_towns_2qry = AU_get_addr_data(addr_info, "towns_2qry", towns_2qry)
	if(n_towns_2qry == 0){
		printf("ERROR: %s: no \"towns_2qry\" data\n", ai_file) > "/dev/stderr"
		err = 1
		exit err
	}
	n_st_types_2qry = AU_get_addr_data(addr_info, "st_types_2qry", st_types_2qry)
	if(n_st_types_2qry == 0){
		printf("ERROR: %s: no \"st_types_2qry\" data\n", ai_file) > "/dev/stderr"
		err = 1
		exit err
	}
	n_dirs_2qry = AU_get_addr_data(addr_info, "dirs_2qry", dirs_2qry)
	if(n_dirs_2qry == 0){
		printf("ERROR: %s: no \"dirs_2qry\" data\n", ai_file) > "/dev/stderr"
		err = 1
		exit err
	}
	n_ords_2qry = AU_get_addr_data(addr_info, "ords_2qry", ords_2qry)
	if(n_ords_2qry == 0){
		printf("ERROR: %s: no \"ords_2qry\" data\n", ai_file) > "/dev/stderr"
		err = 1
		exit err
	}

#tm 	for(k in config){
#tm 		split(k, keys, SUBSEP)
#tm 		if(keys[1] == "dirs")
#tm 			dirs[keys[2]] = config[k]
#tm 		else if(keys[1] == "st_abbrevs")
#tm 			st_abbrevs[keys[2]] = config[k]
#tm 		else if(keys[1] == "st_quals")
#tm 			st_quals[keys[2]] = config[k]
#tm 		else if(keys[1] == "towns")
#tm 			towns[keys[2]] = config[k]
#tm 		else{
#tm 			printf("ERROR: unknown table %s in config file %s\n", keys[1], cfile) > "/dev/stderr"
#tm 			err = 1 
#tm 			exit 1
#tm 		}
#tm 	}

	pr_hdr = 1
}
$5 == "Job" {
	date = $1
	src = $6
	dst = $7

	err = AU_parse(0, 1, atype == "src" ? src : dst, result, towns_2qry, st_types_2qry, "", dirs_2qry, ords_2qry)
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
