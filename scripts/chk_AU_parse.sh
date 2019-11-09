#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -v ] [ -c conf-file ] [ -db db-file ] [ ratqr-file (tsv-file of as_reason, address, a_type, qry_address, rply_address)]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

TMP_DFILE=/tmp/ratqr.$$

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

VERBOSE=
AI_FILE=$DM_ETC/address.info
USE_DB=
DM_DB=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-v)
		VERBOSE="yes"
		shift
		;;
	-c)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-c requires conf-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		AI_FILE=$1
		shift
		;;
	-db)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-db requires db-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		USE_DB="yes"
		DM_DB=$1
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

if [ "$USE_DB" == "yes" ] ; then
	if [ ! -z "$FILE" ] ; then
		LOG ERROR "-db not allowed with aqtr-file"
		echo "$U_MSG" 1>&2
		exit 1
	elif [ ! -s $DM_DB ] ; then
		LOG ERROR "database $DM_DB either does not exist or has zero size"
		exit 1
	fi
	sqlite3 $DM_DB <<-_EOF_ > $TMP_DFILE
	.mode tabs
	PRAGMA foreign_keys = on ;
	SELECT as_reason, address, a_type, qry_address, rply_address
	FROM addresses
	WHERE as_reason LIKE 'geo.ok.%' ;
	_EOF_
	FILE=$TMP_DFILE
fi

$AWK -F'\t' '
@include '"$CFG_UTILS"'
@include '"$ADDR_UTILS"'
BEGIN {
	verbose = "'"$VERBOSE"'" == "yes"

	ai_file = "'"$AI_FILE"'"
	if(CFG_read(ai_file, addr_info)){
		err = 1
		exit err
	}

	if(AU_init(addr_info, us_states, us_states_long, towns_a2q, towns_r2q, st_types_2qry, dirs_2qry, ords_2qry)){
		err = 1
		exit err
	}

 	pa_options["rply"] = 0
 	pa_options["do_subs"] = 1
 	pa_options["no_name"] = "Residence"

 	pq_options["rply"] = 0
 	pq_options["do_subs"] = 1
 	pq_options["no_name"] = "Residence"

 	pr_options["rply"] = 1
 	pr_options["do_subs"] = 1
 	pr_options["no_name"] = ""

	mt_options["verbose"] = verbose
	mt_options["ign_zip"] = 1
	mt_options["no_name"] = "Residence"
}
{
	reason = $1
	addr = $2
	a_type = $3
	qry_addr = $4
	rply_addr = $5

	# chk addr -> qry (std -> qry)
	AU_parse(pa_options, addr, addr_ary, us_states, us_states_long, towns_a2q, st_types_2qry, dirs_2qry, ords_2qry)

	# split the query address info fields
	AU_parse(pq_options, qry_addr, qry_ary, us_states, us_states_long, towns_a2q, st_types_2qry, dirs_2qry, ords_2qry)
	qry_ary["name"] = a_type

	aq_match = AU_match(mt_options, addr_ary, qry_ary)

	# chk rply -> qry, "set geocoder specific flags
	# TODO: make this less brittle
	split(reason, ary, ".")
	geo = ary[3]
	pr_options["us_only"] = (geo == "geo") || (geo == "ss")
	AU_parse(pr_options, rply_addr, rply_ary, us_states, us_states_long, towns_r2q, st_types_2qry, dirs_2qry, ords_2qry)

	qr_match = AU_match(mt_options, qry_ary, rply_ary)

	if(!aq_match || !qr_match){
		n_errors++
		printf("%s: %s = {\n", geo, addr)
		if(!aq_match){
			printf("\taq_match = %d, %s\n", aq_match, qry_ary["emsg"])
			printf("\taddr = {\n")
			printf("\t\tname   = %s\n", addr_ary["name"])
			printf("\t\tstreet = %s\n", addr_ary["street"])
			printf("\t\ttown   = %s\n", addr_ary["town"])
			printf("\t\tstate  = %s\n", addr_ary["state"])
			printf("\t}\n")
			printf("\tqry  = {\n")
			printf("\t\tname   = %s\n", qry_ary["name"])
			printf("\t\tstreet = %s\n", qry_ary["street"])
			printf("\t\ttown   = %s\n", qry_ary["town"])
			printf("\t\tstate  = %s\n", qry_ary["state"])
			printf("\t}\n")
		}
		if(!qr_match){
			printf("\tqr_match = %d, %s\n", qr_match, rply_ary["emsg"])
			printf("\tqry  = {\n")
			printf("\t\tname   = %s\n", qry_ary["name"])
			printf("\t\tstreet = %s\n", qry_ary["street"])
			printf("\t\ttown   = %s\n", qry_ary["town"])
			printf("\t\tstate  = %s\n", qry_ary["state"])
			printf("\t}\n")
			printf("\trply = {\n")
			printf("\t\tname   = %s\n", rply_ary["name"])
			printf("\t\tstreet = %s\n", rply_ary["street"])
			printf("\t\ttown   = %s\n", rply_ary["town"])
			printf("\t\tstate  = %s\n", rply_ary["state"])
			printf("\t}\n")
		}
		printf("}\n")
	}else
		n_ok++
}
END {
	if(!err)
		printf("%s: %d addrs, %d OK, %d errors\n", n_errors > 0 ? "ERROR" : "INFO", NR, n_ok, n_errors) > "/dev/stderr"
	exit err
}' $FILE

rm -f $TMP_DFILE
