#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -v ] [ -d N ] [ -efmt { new* | old } ] [ -gl gc-list ] { -a address | [ address-file ] }"

NOW="$(date +%Y%m%d_%H%M%S)"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

. $DM_ETC/geocoder_defs.sh

TMP_AFILE=/tmp/addrs.$$
TMP_OFILE=/tmp/out.$$
TMP_EFILE=/tmp/err.$$
TMP_EFILE_1=/tmp/err_1.$$
TMP_EFILE_2=/tmp/err_2.$$

VERBOSE=
DELAY=
EFMT=new
GC_LIST=
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
	-gl)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-gl requires gc-list argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GC_LIST=$1
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

# chk that only one of -a ADDR or FILE is set
if [ ! -z "$ADDR" ] ; then
	if [ ! -z "$FILE" ] ; then
		LOG ERROR "-a address not allowed with address-file"
		echo "$U_MSG" 1>&2
		exit 1
	fi
else
	AFILE=$FILE
fi

# do the work
for geo in $(echo $GC_LIST | tr ',' ' '); do
	if [ ! -z "$ADDR" ] ; then
		echo "$ADDR"
	else
		cat $AFILE
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
	}'									|\
	$DM_SCRIPTS/get_addrs_from_runs.sh -at src				|\
	$DM_SCRIPTS/add_geo_to_addrs.sh $VERBOSE $DELAY $EFMT -geo $geo -at src	>> $TMP_OFILE 2> $TMP_EFILE_1
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
		grep '^ERROR' $TMP_EFILE | awk -F'\t' '{ print $4 }' > $TMP_AFILE
		# 2nd and subsequent passes always read from file
		ADDR=
		AFILE=$TMP_AFILE
	fi
done

cat $TMP_OFILE
LOG INFO "$n_OFILE/$n_ADDRS addresses were found"
if [ -s $TMP_EFILE ] ; then
	LOG ERROR "$n_EFILE_1/$n_ADDRS addresses were not found"
	cat $TMP_EFILE 1>&2
fi

rm -f $TMP_AFILE $TMP_OFILE $TMP_EFILE $TMP_EFILE_1 $TMP_EFILE_2
