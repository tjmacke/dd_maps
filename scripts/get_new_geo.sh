#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] geo-dir"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

GEO_DIR=

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
		GEO_DIR=$1
		shift
		break
		;;
	esac
done

if [ -z "$GEO_DIR" ] ; then
	LOG ERROR "missing geo-dir"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -d $GEO_DIR ] ; then
	LOG ERROR "geo-dir $GEO_DIR does not exit or is not a directory"
	exit 1
fi

NOW="$(date +%Y%m%dT%H%M%S)"

echo -e ".mode tabs\nSELECT * FROM addresses WHERE a_stat = 'G' AND as_reason = 'new' ; "	|\
sqlite3 $DM_DB										|\
awk -F'\t' 'BEGIN {
	pr_hdr = 1
}
{
	if(pr_hdr){
		pr_hdr = 0
		printf("%s\t%s\t%s\t%s\t%s\t%s\n", "status", "date", "src", "dst", "qSrc", "sName")
	}
	printf("%s\t%s\t%s\t%s\t%s\t%s\n", $2, ".", $4, ".", $6, $5)
}'	| $DM_SCRIPTS/add_geo_to_addresses.sh -at src > $GEO_DIR/addrs.$NOW.tsv 2> $GEO_DIR/addrs.$NOW.err
