#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -c conf-file -gt { points | lines } [ -t title ] [ address-data-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	GEO_UTILS="$DM_LIB/geo_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	GEO_UTILS="\"$DM_LIB/geo_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

CFILE=
GTYPE=
TITLE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-c)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-c requires conf-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		CFILE=$1
		shift
		;;
	-gt)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-gt requires geometry-type argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GTYPE=$1
		shift
		;;
	-t)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-t requires title argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		TITLE="$1"
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

if [ -z "$CFILE" ] ; then
	LOG ERROR "missing -c conf-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$GTYPE" ] ; then
	LOG ERROR "missing -gt geometry-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$GTYPE" != "points" ] && [ "$GTYPE" != "lines" ] ; then
	LOG ERROR "unknown geomtry-type $GTYPE, must points or lines"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$GTYPE" == "points" ] ; then
	skeys="-k 4,4 -k 5,5"
else
	skeys="-k 3,3 -k 9,9 -k 10,10"
fi

sort -t $'\t' $skeys $FILE |\
$AWK -F'\t' '
@include '"$GEO_UTILS"'
BEGIN {
	cfile = "'"$CFILE"'"
	title = "'"$TITLE"'"
}
{
	# Rules:
	# 1. All lines must have the same number of fields
	# 2. Number of fields must 5 or 10 (points or lines)
	# 3. For points, find point groups or src lng/lat
	# 4. For lines, find point groups on dst lng/lat; put src point once

	if(n_fields == 0)
		n_fields = NF
	else if(NF != n_fields){
		printf("ERROR: line %d: wrong number of fields %d must be %d\n", NR, NF, n_fields) > "/dev/stderr"
		err = 1
		exit err
	}
	n_points++
	colors[n_points] = $1
	styles[n_points] = $2
	titles[n_points] = $3
	longs[n_points] = $4
	lats[n_points] = $5

	if(n_fields == 10){
		colors_2[n_points] = $6
		styles_2[n_points] = $7
		titles_2[n_points] = $8
		longs_2[n_points] = $9
		lats_2[n_points] = $10
	}
}
END {
	if(err)
		exit err

	if(n_points == 0)
		exit 0

	printf("{\n")

	# add the configuation
	printf("\"config\": ")
	for( ; (getline cline < cfile) > 0; )
		printf("%s\n", cline)
	printf(",\n")
	close(cfile)

	# add the geojson
	printf("\"geojson\": {\n")
	printf("\"type\": \"FeatureCollection\",\n")
	printf("\"metadata\": {\n")
	printf("  \"generated\": \"%s\",\n", strftime("%Y%m%dT%H%M%S%z"))
	if(title != "")
		printf("  \"title\": \"%s\",\n", title)
	printf("  \"count\": %d\n", n_points)
	printf("},\n")
	printf("\"features\": [\n")
	if(n_fields == 5){
		# code for points
		# points have been sorted on geo so points w/same geo are consecutive
		n_pgroups = GU_find_pgroups(1, n_points, longs, lats, pg_starts, pg_counts)
		for(i = 1; i <= n_pgroups; i++){
			GU_geo_adjust(longs[pg_starts[i]], lats[pg_starts[i]], pg_counts[i], long_adj, lat_adj)
			for(j = 0; j < pg_counts[i]; j++){
				s_idx = pg_starts[i] + j;
				GU_mk_point("/dev/stdout",
					colors[s_idx], styles[s_idx], longs[s_idx] + long_adj[j+1], lats[s_idx] + lat_adj[j+1], titles[s_idx], s_idx == n_points)
			}
		}
	}else{
		# code for lines
		# dst for each src have been sorted on geo, so dst w/same geo are consecutive
		# find source groups
		sg_start = 1
		sg_count = 1
		sg_title = titles[sg_start]
		for(p = 2; p <= n_points; p++){
			if(titles[p] != sg_title){
				n_pgroups = GU_find_pgroups(sg_start, sg_count, longs_2, lats_2, pg_starts, pg_counts)
				put_src = 1
				for(i = 1; i <= n_pgroups; i++){
					s_idx = pg_starts[i]
					# Put the source point
					if(put_src){
						put_src = 0
						s_idx = pg_starts[i]
						GU_mk_point("/dev/stdout", colors[s_idx], styles[s_idx], longs[s_idx], lats[s_idx], titles[s_idx], 0)
					}

					# Put the dst points
					GU_geo_adjust(longs_2[pg_starts[i]], lats_2[pg_starts[i]], pg_counts[i], long_adj, lat_adj)
					for(j = 0; j < pg_counts[i]; j++){
						d_idx = pg_starts[i] + j
						GU_mk_point("/dev/stdout", colors_2[d_idx], styles_2[d_idx],
							longs_2[d_idx] + long_adj[j+1], lats_2[d_idx] + lat_adj[j+1], titles_2[d_idx], 0)
						GU_mk_line("/dev/stdout", longs[s_idx], lats[s_idx], longs_2[d_idx], lats_2[d_idx], d_idx == n_points)
					}
				}
				sg_start = p
				sg_count = 1
				sg_title = titles[p]
			}else
				sg_count++
		}
		n_pgroups = GU_find_pgroups(sg_start, sg_count, longs_2, lats_2, pg_starts, pg_counts)
		put_src = 1
		for(i = 1; i <= n_pgroups; i++){
			s_idx = pg_starts[i]
			# Put the source point
			if(put_src){
				put_src = 0
				GU_mk_point("/dev/stdout", colors[s_idx], styles[s_idx], longs[s_idx], lats[s_idx], titles[s_idx], 0)
			}

			# Put the dst points
			GU_geo_adjust(longs_2[pg_starts[i]], lats_2[pg_starts[i]], pg_counts[i], long_adj, lat_adj)
			for(j = 0; j < pg_counts[i]; j++){
				d_idx = pg_starts[i] + j;
				GU_mk_point("/dev/stdout", colors_2[s_idx], styles_2[s_idx],
					longs_2[d_idx] + long_adj[j+1], lats_2[d_idx] + lat_adj[j+1], titles_2[d_idx], 0)
				GU_mk_line("/dev/stdout", longs[s_idx], lats[s_idx], longs_2[d_idx], lats_2[d_idx], d_idx == n_points)
			}
		}
	}
	printf("]\n")

	printf("}\n")
	printf("}\n")
}'
