#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] { -a address | [ address-file ] }"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

NOW="$(date +%Y%m%d_%H%M%S)"

ADDR=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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

if [ ! -z "$ADDR" ] ; then
	if [ ! -z "$FILE" ] ; then
		LOG ERROR "-a addr not allowed with address-file"
		echo "$U_MSG" 1>&2
		exit 1
	fi
	echo "$ADDR"
else
	cat $FILE
fi	|\
awk -F'\t' 'BEGIN {
}
{
	if($0 ~ /^#/)
		next
	printf("%s\t.\t.\t.\tJob\t%s\t.\n", strftime("%Y-%m-%d"), $1)
}'												|\
$DM_SCRIPTS/get_addrs_from_runs.sh -at src							|\
$DM_SCRIPTS/add_geo_to_addrs.sh -at src
