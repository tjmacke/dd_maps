#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -limit N ] [ -json json-file ] [ -geo geocoder ] canonical-address"

# TODO: fix this evil dependency
JU_HOME=~
JU_BIN=$JU_HOME/bin

KEY=$(cat ~/etc/opencagedata.key)

LIMIT=
JFILE=
GEO=ocd
ADDR=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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
	-json)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-json requries json-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		JFILE=$1
		shift
		;;
	-geo)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-geo requires geocoder argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GEO=$1
		shift
		;;
	-*)
		LOG ERROR "unknown option $1"
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
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ ! -z "$JFILE" ] ; then
	TEE="tee $JFILE"
else
	TEE=cat
fi

if [ -z "$ADDR" ] ; then
	LOG ERROR "missing canonical-address argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

E_ADDR="$(echo "$ADDR" |\
	awk 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		if(index($0, "+")){
			e_addr = ""
		}else{
			e_addr = $0
			gsub(" ", "+", e_addr)
			gsub(apos, "%27", e_addr)
			gsub(",", "%2C", e_addr)
		}
		print e_addr
	}'
)"
if [ -z "$E_ADDR" ] ; then
	LOG ERROR "can't encode address $ADDR"
	echo ""
	exit 1
fi

if [ "$GEO" == "ocd" ] ; then
	KEY=$(cat ~/etc/opencagedata.key)
	PARMS="query=$E_ADDR&key=$KEY"
	if [ ! -z "$LIMIT" ] ; then
		PARMS="${PARMS}&limit=$LIMIT" 
	fi
	curl -s -S https://api.opencagedata.com/geocode/v1/json?"$PARMS"	|\
	$TEE									|\
	$JU_BIN/json_get -g '{results}[1:$]{confidence, formatted, geometry}{lat, lng},{timestamp}{created_unix}'	|\
	sort -k 1rn,1
elif [ "$GEO" == "geocodio" ] ; then
	KEY=$(cat ~/etc/geocodio.key)
	PARMS="q=$E_ADDR&api_key=$KEY"
	curl -s -S https://api.geocod.io/v1/geocode?"$PARMS"	|\
	$TEE							|\
	$JU_BIN/json_get -g '{results}[1]{accuracy_type, formatted_address, location}{lat, lng}'
else 
	LOG ERROR "unknown geocoder $GEO"
	exit 1
fi

exit 0
