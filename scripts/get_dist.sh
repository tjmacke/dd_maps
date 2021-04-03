#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] addr-1 addr-2"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support includes
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	GEO_UTILS="$DM_LIB/geo_utils.awk"
elif [ "$AWK_VERSION" == "4" ] || [ "$AWK_VERSION" == "5" ] ; then
	AWK=awk
	GEO_UTILS="\"$DM_LIB/geo_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3, 4 or 5"
	exit 1
fi

TMP_OFILE=/tmp/out.$$
TMP_EFILE=/tmp/err.$$

ADDR_1=
ADDR_2=

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
		if [ -z "$ADDR_1" ] ; then
			ADDR_1="$1"
			shift
		elif [ -z "$ADDR_2" ] ; then
			ADDR_2="$1"
			shift
			break
		fi
		;;
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$ADDR_1" ] ; then
	LOG ERROR "missing addr arguments"
	echo "$U_MSG" 1>&2
	exit 1
elif [ -z "$ADDR_2" ] ; then
	LOG ERROR "missing addr-2 argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

if echo -e "$ADDR_1\n$ADDR_2" | $DM_SCRIPTS/get_geo_for_addrs.sh -d 1 > $TMP_OFILE 2> $TMP_EFILE ; then
	awk -F'\t' '
	@include '"$GEO_UTILS"'
	{
		n_addrs++
		addrs[n_addrs] = $2
		lon[n_addrs] = $4
		lat[n_addrs] = $5
	}
	END {
		printf("d(\"%s\", \"%s\") = %5.3f miles\n", addrs[1], addrs[2], GU_gc_dist(lon[1], lat[1], lon[2], lat[2])) 
	}' $TMP_OFILE
else
	cat $TMP_EFILE
fi

rm -f $TMP_OFILE $TMP_EFILE
