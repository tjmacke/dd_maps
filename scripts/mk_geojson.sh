#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -c conf-file -gt { points | lines } [ address-data-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

CFILE=
GTYPE=
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
awk -F'\t' 'BEGIN {
	PI = 4 * atan2(1, 1)
	RAD = 0.0001
	cfile = "'"$CFILE"'"
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
	printf("\"points\": [\n")
	if(n_fields == 5){
		# code for points
		# points have been sorted on geo so points w/same geo are consecutive
		n_pgroups = find_pgroups(1, n_points, longs, lats, pg_starts, pg_counts)
		for(i = 1; i <= n_pgroups; i++){
			geo_adjust(longs[pg_starts[i]], lats[pg_starts[i]], pg_counts[i], long_adj, lat_adj)
			for(j = 0; j < pg_counts[i]; j++){
				h_color = colors[pg_starts[i] + j] != "."
				h_style = styles[pg_starts[i] + j] != "."
				printf("{\n")
				printf("  \"type\": \"Feature\",\n")
				printf("  \"geometry\": {")
				printf("\"type\": \"Point\", ")
				printf("\"coordinates\": [%.5f, %.5f]", longs[pg_starts[i] + j] + long_adj[j+1], lats[pg_starts[i] + j] + lat_adj[j+1])
				printf("},\n")
				printf("  \"properties\": {\n")
				printf("    \"title\": \"%s\",\n", titles[pg_starts[i] + j])
				if(h_color)
					printf("    \"marker-color\": \"%s\"%s\n", colors[pg_starts[i] + j], h_style ? "," : "")
				if(h_style)
					printf("    %s\n", styles[pg_starts[i] + j])
				printf("  }\n")
				printf("}%s\n", (pg_starts[i] + j < n_points) ? "," : "")
			}
		}
	}else{
		# code for lines
		# dst for each src have been sorted on geo, so dst w/same geo are consecutive
		# find source groups
		sg_start = 1
		sg_count = 1
		sg_title = titles[sg_start]
		for(i = 2; i <= n_points; i++){
			if(titles[i] != sg_title){
				n_pgroups = find_pgroups(sg_start, sg_count, longs_2, lats_2, pg_starts, pg_counts)
				printf("sg: %4d %2d %d %s\n", sg_start, sg_count, n_pgroups, sg_title)

				sg_start = i
				sg_count = 1
				sg_title = titles[i]
			}else
				sg_count++
		}
		n_pgroups = find_pgroups(sg_start, sg_count, longs_2, lats_2, pg_starts, pg_counts)
		printf("sg: %4d %2d %d %s\n", sg_start, sg_count, n_pgroups, sg_title)
	}
	printf("]\n")

	printf("}\n")
}
function find_pgroups(start, count, longs, lats, pg_starts, pg_counts,   n_pgroups, l_geo, geo, i) {

	n_pgroups = 1
	pg_starts[n_pgroups] = start
	pg_counts[n_pgroups] = 1
	l_geo[1] = longs[start]
	l_geo[2] = lats[start]
	for(i = 1; i < count; i++){
		geo[1] = longs[start + i]
		geo[2] = longs[start + i]
		if(geo_equal(geo, l_geo)){
			pg_counts[n_pgroups]++
		}else{
			n_pgroups++
			pg_starts[n_pgroups] = start + i
			pg_counts[n_pgroups] = 1
		}
		l_geo[1] = geo[1]
		l_geo[2] = geo[2]
	}

	return n_pgroups
}
function geo_equal(g1, g2) {
	return g1[1] == g2[1] && g1[2] == g2[2]
}
function geo_isnull(g) {
	return g[1] == "" || g[2] == ""
}
function geo_adjust(long, lat, n, long_adj, lat_adj,   i, a) {

	long_adj[1] = 0
	lat_adj[1] = 0
	if(n > 1){
		a = 2.0*PI/(n-1)
		for(i = 2; i <= n; i++){
			long_adj[i] = RAD * sin(a * (i-2))
			lat_adj[i] = RAD * cos(a * (i-2))
		}
	}
}'
