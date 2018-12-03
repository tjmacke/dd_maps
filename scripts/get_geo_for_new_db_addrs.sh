#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -db db-file [ -efmt { new* | old } ] [ -geo geocoder ] [ -limit N ] geo-dir"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
# set these from the cmd line
#DM_ADDRS=$DM_HOME/addrs
#DM_DB=$DM_ADDRS/dd_maps.db

#if [ ! -s $DM_DB ] ; then
#	LOG ERROR "database $DM_DB either does not exist or has zero size"
#	exit 1
#fi

rval=0
NOW="$(date +%Y%m%dT%H%M%S)"

DM_DB=
EFMT=new
GEO=
LIMIT=
GEO_DIR=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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
	-db)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-db requires db-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DM_DB=$1
		shift
		;;
	-geo)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-geo requires geocoder"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GEO=$1
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

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ "$EFMT" != "new" ] && [ "$EFMT" != "old" ] ; then
	LOG ERROR "unknown error format: $EFMT, must be new or old"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing -db db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

if [ ! -z "$LIMIT" ] ; then
	LIMIT="LIMIT $LIMIT"
fi

# keep track of which geocoder we're using.  geocod.io (geo) is still default
if [ ! -z "$GEO" ] ; then
	GC_NAME=$GEO
	GEO="-geo $GEO"		# set flag for add_geo_to_addrs.sh
else
	GC_NAME="geo"
fi
GEO_TSV_FNAME=addrs.$NOW.$GC_NAME.tsv
GEO_ERR_FNAME=addrs.$NOW.$GC_NAME.err

if [ -z "$GEO_DIR" ] ; then
	LOG ERROR "missing geo-dir"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -d $GEO_DIR ] ; then
	LOG ERROR "geo-dir $GEO_DIR does not exit or is not a directory"
	exit 1
fi

echo -e ".mode tabs\nPRAGMA foreign_keys = on ;\nSELECT * FROM addresses WHERE a_stat = 'G' AND as_reason = 'new' $LIMIT ;"	|\
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
}'	| $DM_SCRIPTS/add_geo_to_addrs.sh $GEO -at src > $GEO_DIR/$GEO_TSV_FNAME 2> $GEO_DIR/$GEO_ERR_FNAME

n_tsv=$(cat $GEO_DIR/$GEO_TSV_FNAME | wc -l)
n_err=$(grep '^ERROR:' $GEO_DIR/$GEO_ERR_FNAME | wc -l)
n_addr=$((n_tsv + n_err))
LOG INFO "geocoder $GC_NAME: $n_tsv/$n_addr addresses were resolved: details in $GEO_DIR/$GEO_TSV_FNAME"
if [ $n_err -gt 0 ] ; then
	LOG ERROR "geocoder $GC_NAME: $n_err/$n_addr addresses were not resolved: details in $GEO_DIR/$GEO_ERR_FNAME"
	rval=1
fi

exit $rval
