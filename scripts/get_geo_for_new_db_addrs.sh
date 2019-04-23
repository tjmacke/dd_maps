#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -d N ] [ -efmt { new* | old } ] [ -gl gc-list ] [ -limit N ] db"

TODAY="$(date +%Y%m%d)"

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
TMP_OFILE_1=/tmp/out_1.$$
TMP_EFILE=/tmp/err.$$
TMP_EFILE_1=/tmp/err_1.$$
TMP_EFILE_2=/tmp/err_2.$$

DELAY=
EFMT=new
GC_LIST=
LIMIT=
DM_DB=

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
		DM_DB=$1
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

if [ ! -z "$LIMIT" ] ; then
	LIMIT="LIMIT $LIMIT"
fi

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

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing db argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

rval=0

# this is a test query that finds #6 w/geo, #48 w/ocd and both miss on #80
#echo -e ".mode tabs\nPRAGMA foreign_keys = on ;\nSELECT * FROM addresses WHERE address_id in (6, 48, 80) ;"	|\

# this is the real query
# echo -e ".mode tabs\nPRAGMA foreign_keys = on ;\nSELECT * FROM addresses WHERE a_stat = 'G' AND as_reason = 'new' $LIMIT ;"	|\

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
n_ADDRS=$(tail -n +2 $TMP_AFILE | wc -l | tr -d ' ')
LOG INFO "get geo for $n_ADDRS addresses"

# do the work
n_FOUND=0
for geo in $(echo $GC_LIST | tr ',' ' '); do
	$DM_SCRIPTS/add_geo_to_addrs.sh $DELAY $EFMT -geo $geo -at src $TMP_AFILE_1 > $TMP_OFILE_1 2> $TMP_EFILE_1
	n_OFILE_1=$(cat $TMP_OFILE_1 | wc -l | tr -d ' ')
	n_FOUND=$((n_OFILE_1 + n_FOUND))
	LOG INFO "found $n_OFILE_1 addresses using geocoder $geo"
	if [ -s $TMP_OFILE_1 ] ; then
		$DM_SCRIPTS/update_addrs_with_geo_loc.sh -db $DM_DB -d $TODAY -geo $geo -at src < $TMP_OFILE_1
	fi

	# TODO: put this under a switch in case this data is not wanted
	cat $TMP_OFILE_1 >> $TMP_OFILE

	n_EFILE_1=$(grep '^ERROR' $TMP_EFILE_1 | wc -l | tr -d ' ')
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

# TODO: put this under a switch in case this data is not wanted
cat $TMP_OFILE

LOG INFO "$n_FOUND/$n_ADDRS addresses were found"
if [ -s $TMP_EFILE ] ; then
	LOG ERROR "$n_EFILE_1/$n_ADDRS addresses were not found"
	$DM_SCRIPTS/update_addrs_with_geo_errors.sh -db $DM_DB -d $TODAY < $TMP_EFILE
	cat $TMP_EFILE_1 1>&2
fi

rm -f $TMP_AFILE $TMP_AFILE_1 $TMP_OFILE $TMP_OFILE_1 $TMP_EFILE $TMP_EFILE_1 $TMP_EFILE_2

exit $rval
