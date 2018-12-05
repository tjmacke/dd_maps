#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -v ] [ -d N ] [ -efmt { new* | old } ] [ -geo geocoder ] { -a address | [ address-file ] }"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

NOW="$(date +%Y%m%d_%H%M%S)"

VERBOSE=
DELAY=
EFMT=new
GEO=
ADDR=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-v)
		VERBOSE="-v"
		shift
		;;
	-d)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-d requires integer argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DELAY=$1
		shift
		;;
	-efmt)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-efmt requires format string"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		EFMT=$1
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
	-a)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-a requires address argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		ADDR="$1"
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

if [ ! -z "$DELAY" ] ; then
	DELAY="-d $DELAY"
fi

if [ "$EFMT" != "new" ] && [ "$EFMT" != "old" ] ; then
	LOG ERROR "unknown error fmt: $EFMT, must be new or old"
	echo "$U_MSG" 1>&2
	exit 1
else
	EFMT="-efmt $EFMT"
fi

if [ ! -z "$GEO" ] ; then
	GEO="-geo $GEO"
fi

if [ ! -z "$ADDR" ] ; then
	if [ ! -z "$FILE" ] ; then
		LOG ERROR "-a address not allowed with address-file"
		echo "$U_MSG" 1>&2
		exit 1
	fi
	echo "$ADDR"
else
	cat $FILE
fi	|\
awk -F'|' '{
	for(i = 1; i <= NF; i++){
		work = $i
		sub(/^  */, "", work)
		sub(/  *$/, "", work)
		printf("%s\n", work)
	}
}'	|\
awk -F'\t' '
{
	if($0 ~ /^#/)
		next
	printf("%s\t.\t.\t.\tJob\t%s\t.\n", strftime("%Y-%m-%d"), $1)
}'												|\
$DM_SCRIPTS/get_addrs_from_runs.sh -at src							|\
$DM_SCRIPTS/add_geo_to_addrs.sh $VERBOSE $DELAY $EFMT $GEO -at src
