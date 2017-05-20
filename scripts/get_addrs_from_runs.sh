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

 	# check that we got all the data we need
 	ad_counts["n_us_states"] = AU_get_addr_data(addr_info, "us_states", us_states)
 
 	ad_counts["n_towns_a2q"] = AU_get_addr_data(addr_info, "towns_a2q", towns_a2q)
 	ad_counts["n_st_types_2qry"] = AU_get_addr_data(addr_info, "st_types_2qry", st_types_2qry)
 	ad_counts["n_dirs_2qry"] = AU_get_addr_data(addr_info, "dirs_2qry", dirs_2qry)
 	ad_counts["n_ords_2qry"] = AU_get_addr_data(addr_info, "ords_2qry", ords_2qry)
 
 	for(ad in ad_counts){
 		if(ad_counts[ad] == 0){
 			printf("ERROR: %s no \"%s\" data\n", ai_file, substr(ad, 3)) > "/dev/stderr"
 			err = 1
 		}
 	}
 	if(err)
 		exit err

	# create a map of full state names
	for(s in us_states)
		us_states_long[us_states[s]] = s

	pq_options["rply"] = 0
	pq_options["do_subs"] = 1
	pq_options["no_name"] = "Residence"

	pr_hdr = 1
}
$5 == "Job" {
	date = $1
	src = $6
	dst = $7

	err = AU_parse(pq_options, atype == "src" ? src : dst, addr_ary, us_states, us_states_long, towns_a2q, st_types_2qry, dirs_2qry, ords_2qry)
	if(pr_hdr){
		pr_hdr = 0
		if(atype == "src")
			printf("status\tdate\tsrc\tdst\tqSrc\tsName\n")
		else
			printf("status\tdate\tsrc\tdst\tqDst\tdName\n")
	}
	printf("%s", addr_ary["status"])
	if(addr_ary["status"] == "B")
		printf(", %s", addr_ary["emsg"])
	printf("\t%s\t%s\t%s", date, src, dst)
	if(addr_ary["status"] == "B")
		printf("\t\t")
	else
		printf("\t%s, %s, %s\t%s", addr_ary["street"], addr_ary["town"], addr_ary["state"], addr_ary["name"])
	printf("\n")
}' $FILE
