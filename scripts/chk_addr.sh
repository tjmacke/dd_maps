#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -c addr-info-file ] [ -limit N ] address"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support includes
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
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

TMP_GFILE=/tmp/geo.$$

TODAY="$(date +%Y-%m-%d)"

AI_FILE=$DM_ETC/new_address.info
LIMIT=
ADDR=

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
	-limit)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-limit requires integer argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		LIMIT=$1
		shift
		;;
	-*)
		LOG ERROR "unkonwn option $1"
		echo "$U_MSG" 1>&2
		exit 1
		;;
	*)
		ADDR="$1"
		shift
		break
		;;
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$ADDR" ] ; then
	LOG ERROR "missing address argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ ! -z "$LIMIT" ] ; then
	LIMIT="-limit $LIMIT"
fi

line="$(echo "$ADDR"	|\
$AWK -F'\t' '
@include '"$CFG_UTILS"'
@include '"$ADDR_UTILS"'
BEGIN {
	today = "'"$TODAY"'"

	ai_file="'"$AI_FILE"'"
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
}
{
	# Use qry.line format, with all addreses as src ($3) addresses with dst ($4) set to "."
	if(AU_parse(0, 1, $1, result, towns_2qry, st_types_2qry, "", dirs_2qry, ords_2qry)){
		printf("%s, %s\t%s\t%s\t%s\n", result["status"], result["emsg"], today, $1, ".")
	}else{
		printf("%s\t%s\t%s\t%s\t%s\t%s\n", result["status"], today, $1, ".", result["street"] ", " result["town"] ", CA", result["name"]) 
	}
}')"
stat="$(echo "$line" | awk -F'\t' '{ print $1 }')"
addr="$(echo "$line" | awk -F'\t' '{ print $3 }')"
if [ "$stat" != "G" ] ; then
	emsg="$(echo $stat | awk '{ print $2 }')"
	echo "ERROR: $TODAY: addr: $addr: $emsg" 1>&2
else
	query="$(echo "$line" | awk -F'\t' '{ print $5 }')"
	name="$(echo "$line" | awk -F'\t' '{ print $6 }')"
	$DM_SCRIPTS/get_latlong.sh $LIMIT "$query" > $TMP_GFILE
	$AWK -F'\t' '
	@include '"$CFG_UTILS"'
	@include '"$ADDR_UTILS"'
	BEGIN {
		today = "'"$TODAY"'"

		addr = "'"$addr"'"
		query = "'"$query"'"
		name = "'"$name"'"

		ai_file="'"$AI_FILE"'"
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
		# split the input address into fields.  No need to test, as it worked, else we would not be here.
		AU_parse(0, 0, addr, addr_ary, towns_2qry, st_types_2qry, "", dirs_2qry, ords_2qry)

		n_towns_2std = AU_get_addr_data(addr_info, "towns_2std", towns_2std)
		if(n_towns_2std == 0){
			printf("ERROR: %s: no \"towns_2std\" data\n", ai_file) > "/dev/stderr"
			err = 1
			exit err
		}
		n_st_types_2std = AU_get_addr_data(addr_info, "st_types_2std", st_types_2std)
		if(n_st_types_2std == 0){
			printf("ERROR: %s: no \"st_types_2std\" data\n", ai_file) > "/dev/stderr"
			err = 1
			exit err
		}
		n_dirs_2std = AU_get_addr_data(addr_info, "dirs_2std", dirs_2std)
		if(n_dirs_2std == 0){
			printf("ERROR: %s: no \"dirs_2std\" data\n", ai_file) > "/dev/stderr"
			err = 1
			exit err
		}
		n_ords_2std = AU_get_addr_data(addr_info, "ords_2std", ords_2std)
		if(n_ords_2std == 0){
			printf("ERROR: %s: no \"ords_2std\" data\n", ai_file) > "/dev/stderr"
			err = 1
			exit err
		}
	}
	{
		if(AU_parse(1, 1, $2, result, towns_2std, st_types_2std, "", dirs_2std, ords_2std)){
			n_lines++
			lines[n_lines] = sprintf("emsg  = %s", result["emsg"])
			n_lines++
			lines[n_lines] = sprintf("reply = %s", $2)
			err = 1
		}else{
			# original AU_match(result, addr_ary)
			if(AU_match_2(result, addr_ary)){
				printf("%s\t%s\t%s\t%s\t%s\t%s\n", today, addr, ".", $4, $3, $2)
				err = 0
				exit err
			}else{
				n_lines++
				lines[n_lines] = sprintf("emsg  = %s\t%s", "no.match", $0)
				n_lines++
				lines[n_lines] = sprintf("reply = %s", $2)
				err = 1
			}
		}
	}
	END {
		if(err && n_lines > 0){
			printf("ERROR: %s: addr: %s: not found:\n", today, addr) > "/dev/stderr"
			printf("{\n") > "/dev/stderr"
			printf("\tquery = %s\n", query) > "/dev/stderr"
			for(i = 1; i <= n_lines; i++)
				printf("\t%s\n", lines[i]) > "/dev/stderr"
			printf("}\n") > "/dev/stderr"		
		}
		exit err
	}' $TMP_GFILE
fi

rm -f $TMP_GFILE
