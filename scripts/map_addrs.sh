#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -cf color-file ] [ -sf style-file] [ -fl flist-json ] -at { src | dst } [ address-geo-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

DEF_COLOR="#aae"
DEF_SIZE="small"

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

CFILE=
SFILE=
FLIST=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-cf)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-cf requires color-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		CFILE=$1
		shift
		;;
	-sf)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-sf requires style-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		SFILE=$1
		shift
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

# input:	6 fields:
#	date	text-1	.	lng	lat	text-2
#
#	text-1 was originally the qry addr and text-2 the rply addr, but they're just text
#
# format required by sort is 5 fields:
#	color	size	title	lng	lat
#
#	title = text-1, lng, lat are passed through, color & size can be taken from files,
#	but default to "#aae" and "small"

cat $FILE	|\
if [ ! -z "$CFILE" ] || [ ! -z "$SFILE" ] ; then
	awk -F'\t' 'BEGIN {
		def_color = "'"$DEF_COLOR"'"
		def_size = "'"$DEF_SIZE"'"

		cfile = "'"$CFILE"'"
		if(cfile != ""){
			for(n_ctab = 0; (getline < cfile) > 0; ){
				n_ctab++
				ctab[n_ctab] = $0
			}
			close(cfile)
		}
		sfile = "'"$SFILE"'"
		if(sfile != ""){
			for(n_stab = 0; (getline < sfile) > 0; ){
				n_stab++
				stab[n_stab] = $0
			}
			close(sfile)
		}
	}
	{
#		printf("%s\t%s\t%s\t%s\t%s\n", NR <= n_ctab ? ctab[NR] : def_color, NR <= n_stab ? stab[NR] : def_size, $2, $4, $5)
		printf("%s\t%s\t%s\t%s\t%s\n", NR <= n_ctab ? ctab[NR] : def_color, NR <= n_stab ? stab[NR] : def_size, $2, $4, $5)
	}'
else
	awk -F'\t'	'BEGIN {
		def_color = "'"$DEF_COLOR"'"
		def_size = "'"$DEF_SIZE"'"
	}
	{
#		printf("%s\t%s\t%s\t%s\t%s\n", "#aae", ".", $2, $4, $5)
		printf("%s\t%s\t%s\t%s\t%s\n", def_color, def_size, $2, $4, $5)
	}'
fi				|\
sort -t $'\t' -k 4g,4 -k 5g,5	|\
$AWK -F'\t' '
@include '"$GEO_UTILS"'
{
	n_points++
	colors[n_points] = $1
	styles[n_points] = $2
	titles[n_points] = $3
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
	if(flist != ""){
		while((getline line < flist) > 0){
			printf("%s\n", line)
		}
		close(flist)
	}
	GU_pr_trailer()
	exit 0
}'

exit $rval
