#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] canonical-address"

# TODO: fix this evil dependency
JU_HOME=~
JU_BIN=$JU_HOME/bin

KEY=$(cat ~/etc/opencagedata.key)

ADDR=

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
			gsub(apos, "%27", e_addr)
			gsub(" ", "+", e_addr)
		}
		print e_addr
	}'
)"
if [ -z "$E_ADDR" ] ; then
	LOG ERROR "can't encode address $ADDR"
	echo ""
	exit 1
fi
PARMS="query=$E_ADDR&key=$KEY"

curl -s -S https://api.opencagedata.com/geocode/v1/json?"$PARMS"		|\
$JU_BIN/json_get -g '{results}[1:$]{confidence, formatted, geometry}{lat, lng}'	|\
sort -k 1rn,1
exit 0
