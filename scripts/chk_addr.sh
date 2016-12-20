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
	-hdr)
		HDR="yes"
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
}
{
	if(AU_parse(0, 1, $1, result, towns_2qry, st_types_2qry, "", dirs_2qry)){
		printf("2qry: %s, %s\t%s\n", result["status"], result["emsg"], $1)
	}else{
		quals = result["quals"] != "" ? result["quals"] : "."
		printf("%s\t%s\t%s\t%s\t%s\n", result["status"], $1, result["street"] ", " result["town"] ", CA", quals, result["name"])
	}
}')"

stat="$(echo "$line" | awk -F'\t' '{ print $1 }')"
if [ "$stat" != "G" ] ; then
	addr="$(echo "$line" | awk -F'\t' '{ print $2 }')"
	echo "ERROR: bad address: $stat: $addr" 1>&2
else
	addr="$(echo "$line" | awk -F'\t' '{ print $2 }')"
	query="$(echo "$line" | awk -F'\t' '{ print $3 }')"
	quals="$(echo "$line" | awk -F'\t' '{ print $4 }')"
	name="$(echo "$line" | awk -F'\t' '{ print $5 }')"
	$DM_SCRIPTS/get_latlong.sh $LIMIT "$query" > $TMP_GFILE
	$AWK -F'\t' '
	@include '"$CFG_UTILS"'
	@include '"$ADDR_UTILS"'
	BEGIN {
		today = "'"$TODAY"'"

		addr = "'"$addr"'"
		query = "'"$query"'"
		quals = "'"$quals"'"
		if(quals == ".")
			quals = ""
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
		# split the input address into fields.  No need to test, as it worked, else we would not be here.
		AU_parse(0, 0, addr, addr_ary, towns_2qry, st_types_2qry, "", dirs_2qry)

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
	}
	{
		if(AU_parse(1, 1, $2, result, towns_2std, st_types_2std, "", dirs_2std)){
			n_lines++
			lines[n_lines] = sprintf("2std: %s, %s\t%s", result["status"], result["emsg"], $0)
		}else{

			# AU_match() handles street ranges, turn it on some day
			printf("DEBUG: _main_: AU_match() = %d\n", AU_match(result, addr_ary)) > "/dev/stderr"

			cand = ""
			if(name != "Residence")
				cand = name ", "
			cand = cand result["street"]
			if(quals != "")
				cand = cand ", " quals
			cand = cand ", " result["town"]
			if(cand == addr){
				printf("%s\t%s\t%s\t%s\t%s\t%s\n", today, addr, ".", $4, $3, $2)
				err = 0
				exit err
			}else{
				n_lines++
				lines[n_lines] = sprintf("2std: %s, %s\t%s", "B", "no.match", $0)
			}
		}
	}
	END {
		if(err)
			exit err

		if(n_lines > 0){
			printf("addr:\t\t\t\t%s\n", addr) > "/dev/stderr"
			printf("query:\t\t\t\t%s\n", query) > "/dev/stderr"
			for(i = 1; i <= n_lines; i++)
				printf("%s\n", lines[i]) > "/dev/stderr"
		}
	}' $TMP_GFILE
fi

rm -f $TMP_GFILE
