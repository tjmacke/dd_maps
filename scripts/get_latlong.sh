#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -limit N ] [ -json json-file ] [ -geo geocoder ] canonical-address"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc

. $DM_ETC/geocoder_defs.sh

function ss_post {
	awk -F'\t' '{
		printf("1\t%s, %s, %s %s\t%s\t%s\n", $1, $2, $4, $5, $6, $7)
		if($3 != $2)
			printf("2\t%s, %s, %s %s\t%s\t%s\n", $1, $3, $4, $5, $6, $7)
	}'
}

# TODO: fix this evil dependency
JU_HOME=$HOME/json_utils
JU_BIN=$JU_HOME/bin

CURL_OUT=/tmp/curl.json.$$
CURL_ERR=/tmp/curl.err.$$
JG_ERR=/tmp/jg.err.$$

LIMIT=
JFILE=
GEO=$GEO_PRIMARY
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

if [ "$GEO" == "geo" ] ; then
	KEY=$(cat ~/etc/geocodio.key)
	PARMS="q=$E_ADDR&api_key=$KEY"
	URL="https://api.geocod.io/v1/geocode?$PARMS"
	JG_REQ='{results}[1]{accuracy_type, formatted_address, location}{lat, lng}'
	POST=
elif [ "$GEO" == "ocd" ] ; then
	KEY=$(cat ~/etc/opencagedata.key)
	PARMS="query=$E_ADDR&key=$KEY"
	if [ ! -z "$LIMIT" ] ; then
		PARMS="${PARMS}&limit=$LIMIT" 
	fi
	URL="https://api.opencagedata.com/geocode/v1/json?$PARMS"
	JG_REQ='{results}[1:$]{confidence, formatted, geometry}{lat, lng},{timestamp}{created_unix}'
	POST="sort -k 1rn,1"
elif [ "$GEO" == "ss" ] ; then
	URL_TEMPLATE="https://us-street.api.smartystreets.com/street-address?auth-id=%s&auth-token=%s&street=%s&city=%s&state=%s&candidates=%d"
	AUTH_ID="$(cat ~/etc/smartystreets.auth-id)"
	AUTH_TOKEN="$(cat ~/etc/smartystreets.auth-token)"
	CANDIDATES=10
	URL="$(
		awk 'BEGIN {
			url_template = "'"$URL_TEMPLATE"'"
			auth_id = "'"$AUTH_ID"'"
			auth_token = "'"$AUTH_TOKEN"'"
			addr = "'"$E_ADDR"'"
			candidates = "'"$CANDIDATES"'" + 0
		}
		END {
			n_ary = split(addr, ary, "%2C")	# encoded comma
			printf(url_template, auth_id, auth_token, ary[1], ary[2], ary[3], candidates)
		}' < /dev/null
	)"
	JG_REQ='[1]{delivery_line_1, components}{city_name, default_city_name, state_abbreviation, zipcode},[1]{metadata}{latitude, longitude}'
	# couldn't get the quoting to work, so define a func!
	POST=ss_post
else 
	LOG ERROR "unknown geocoder $GEO"
	exit 1
fi

curl -s -S $URL > $CURL_OUT 2> $CURL_ERR
if [ -s $CURL_ERR ] ; then
	cat $CURL_ERR 1>&2
else
	if [ ! -z "$POST" ] ; then
		$JU_BIN/json_get -g "$JG_REQ" $CURL_OUT 2> $JG_ERR | $POST
	else
		$JU_BIN/json_get -g "$JG_REQ" $CURL_OUT 2> $JG_ERR
	fi
	if [ -s $JG_ERR ] ; then
		cat $JG_ERR 1>&2
	fi
fi

rm -f $CURL_OUT $CURL_ERR $JG_ERR

# TODO: fix this
exit 0
