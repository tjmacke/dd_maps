#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -fl flist-json ] -at { src | dst } [ address-geo-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# TODO: fix this evil dependency
JU_HOME=$HOME/json_utils
JU_BIN=$JU_HOME/bin

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	GEO_UTILS="$DM_LIB/geo_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	GEO_UTILS="\"$DM_LIB/geo_utils.awk\""
else
	LOG ERROR "unsupported awk version \"$AWK_VERSION\", must be 3 or 4"
	exit 1
fi

FLIST=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-fl)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-fl requires flist-json argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		FLIST="$1"
		shift
		;;
	-at)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-at requires address-type argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		ATYPE=$1
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

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

rval=0

sort -t $'\t' -k 4g,4 -k 5g,5 $FILE	|\
$AWK -F'\t' '
@include '"$GEO_UTILS"'
BEGIN {
	flist = "'"$FLIST"'"
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 2 : 3
}
{
	n_points++
	colors[n_points] = "#aae"
	styles[n_points] = "\"marker-size\": \"small\""
	titles[n_points] = $2
	longs[n_points] = $4
	lats[n_points] = $5
}
END {
	if(n_points == 0)
		exit 0

	GU_pr_header("map_addrs", n_points)
	n_pgroups = GU_find_pgroups(1, n_points, longs, lats, pg_starts, pg_counts)
	for(i = 1; i <= n_pgroups; i++){
		GU_geo_adjust(longs[pg_starts[i]], lats[pg_starts[i]], pg_counts[i], long_adj, lat_adj)
		for(j = 0; j < pg_counts[i]; j++){
			s_idx = pg_starts[i] + j
			GU_mk_point("/dev/stdout",
				colors[s_idx], styles[s_idx], longs[s_idx] + long_adj[j+1], lats[s_idx] + lat_adj[j+1], titles[s_idx], ((s_idx == n_points) && !flist))
		}
	}
	# add any other features
	while((getline line < flist) > 0){
		printf("%s\n", line)
	}
	close(flist)
	GU_pr_trailer()
	exit 0
}'

exit $rval
