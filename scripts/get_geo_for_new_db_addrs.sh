#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -db db-file [ -d N ] [ -efmt { new* | old } ] [ -gl gc-list ] [ -limit N ] geo-dir"

NOW="$(date +%Y%m%dT%H%M%S)"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

. $DM_ETC/geocoder_defs.sh

TMP_AFILE=/tmp/addrs.$$
TMP_AFILE_1=/tmp/addrs_1.$$
TMP_OFILE=/tmp/out.$$
TMP_EFILE=/tmp/err.$$
TMP_EFILE_1=/tmp/err_1.$$
TMP_EFILE_2=/tmp/err_2.$$

DM_DB=
DELAY=
EFMT=new
GC_LIST=
LIMIT=
GEO_DIR=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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
	-gl)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-geo requires geocoder"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GC_LIST=$1
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

if [ ! -z "$DELAY" ] ; then
	DELAY="-d $DELAY"
fi

if [ "$EFMT" != "new" ] && [ "$EFMT" != "old" ] ; then
	LOG ERROR "unknown error format: $EFMT, must be new or old"
	echo "$U_MSG" 1>&2
	exit 1
else
	EFMT="-efmt $EFMT"
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

#tm OLD
#tm # keep track of which geocoder we're using.  geocod.io (geo) is still default
#tm if [ ! -z "$GEO" ] ; then
#tm 	GC_NAME=$GEO
#tm 	GEO="-geo $GEO"		# set flag for add_geo_to_addrs.sh
#tm else
#tm 	GC_NAME="geo"
#tm fi
#tm GEO_TSV_FNAME=addrs.$NOW.$GC_NAME.tsv
#tm GEO_ERR_FNAME=addrs.$NOW.$GC_NAME.err
#tm
#tm if [ -z "$GEO_DIR" ] ; then
#tm 	LOG ERROR "missing geo-dir"
#tm 	echo "$U_MSG" 1>&2
#tm 	exit 1
#tm elif [ ! -d $GEO_DIR ] ; then
#tm 	LOG ERROR "geo-dir $GEO_DIR does not exit or is not a directory"
#tm 	exit 1
#tm fi

# set up the geocoder order
if [ -z "$GC_LIST" ] ; then
	GC_LIST="$GEO_PRIMARY,$GEO_SECONDARY"
else
	GC_WORK="$(chk_geocoders $GC_LIST)"
	if echo "$GC_WORK" | grep '^ERROR' > /dev/null ; then
		LOG ERROR "$GC_WORK"
		exit 1
	fi
	GC_LIST=$GC_WORK	# comma sep list w/o spaces
fi

rval=0
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
}'	| tee $TMP_AFILE > $TMP_AFILE_1
# do the work
for geo in $(echo $GC_LIST | tr ',' ' '); do
	$DM_SCRIPTS/add_geo_to_addrs.sh $DELAY $EFMT -geo $geo -at src $TMP_AFILE_1 >> $TMP_OFILE 2> $TMP_EFILE_1
	n_OFILE=$(cat $TMP_OFILE | wc -l)
	n_EFILE_1=$(grep '^ERROR' $TMP_EFILE_1 | wc -l)
	n_ADDRS=$((n_OFILE + n_EFILE_1))
	if [ $n_EFILE_1 -eq 0 ] ; then
		# resolved all addrs; any errors in $TMP_EFILE were fixed so remove it
		rm -f $TMP_EFILE
		break
	else
		# errors
		if [ ! -s $TMP_EFILE ] ; then
			# first time through loop
			mv $TMP_EFILE_1 $TMP_EFILE
		else
			# 2nd and subsequent times through loop
			$DM_SCRIPTS/merge_geo_error_files.sh $TMP_EFILE $TMP_EFILE_1 > $TMP_EFILE_2
			mv $TMP_EFILE_2 $TMP_EFILE
		fi
		grep '^ERROR' $TMP_EFILE |\
		awk -F'\t' 'BEGIN {
			afile = "'"$TMP_AFILE"'"
			for(n_addrs = 0; (getline aline < afile) > 0; ){
				n_addrs++
				n_ary = split(aline, ary, "\t")
				atab[ary[3]] = aline
			}
			close(afile)
			pr_hdr = 1
		}
		{
			if(pr_hdr){
				pr_hdr = 0
				printf("%s\t%s\t%s\t%s\t%s\t%s\n", "status", "date", "src", "dst", "qSrc", "sName")
			}
			print atab[$4]
		}' > $TMP_AFILE_1
	fi
done

cat $TMP_OFILE
LOG INFO "$n_OFILE/$n_ADDRS were found"
if [ -s $TMP_EFILE ] ; then
	LOG ERROR "$n_EFILE_1/$n_ADDRS were not found"
	cat $TMP_EFILE_1 1>&2
fi

rm -f $TMP_AFILE $TMP_AFILE_1 $TMP_OFILE $TMP_EFILE $TMP_EFILE_1 $TMP_EFILE_2

exit $rval
