#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -c conf-file [ address-data-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

CFILE=
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

sort -t $'\t' -k 4,4 -k 5,5 $FILE |\
$AWK -F'\t' 'BEGIN {
	PI = 4 * atan2(1, 1)
	RAD = 0.0001
	cfile = "'"$CFILE"'"
}
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

	printf("{\n")

	# add the configuation
	printf("\"config\": ")
	for( ; (getline cline < cfile) > 0; )
		printf("%s\n", cline)
	printf(",\n")
	close(cfile)

	# points have been sorted on geo so points w/same geo are consecutive
	n_pgroups = 1
	pg_starts[n_pgroups] = 1
	pg_counts[n_pgroups] = 1
	l_geo[1] = longs[1]
	l_geo[2] = lats[1]
	for(i = 2; i <= n_points; i++){
		geo[1] = longs[i]
		geo[2] = lats[i]
		if(geo_equal(geo, l_geo)){
			pg_counts[n_pgroups]++
		}else{
			n_pgroups++
			pg_starts[n_pgroups] = i
			pg_counts[n_pgroups] = 1
		}
		l_geo[1] = geo[1]
		l_geo[2] = geo[2]
	}

	printf("\"points\": [\n")
	for(i = 1; i <= n_pgroups; i++){
		geo_adjust(longs[pg_starts[i]], lats[pg_starts[i]], pg_counts[i], long_adj, lat_adj)
		for(j = 0; j < pg_counts[i]; j++){
			h_style = styles[pg_starts[i] + j] != "."
			printf("{\n")
			printf("  \"type\": \"Feature\",\n")
			printf("  \"geometry\": {")
			printf("\"type\": \"Point\", ")
			printf("\"coordinates\": [%.5f, %.5f]", longs[pg_starts[i] + j] + long_adj[j+1], lats[pg_starts[i] + j] + lat_adj[j+1])
			printf("},\n")
			printf("  \"properties\": {\n")
			printf("    \"title\": \"%s\",\n", titles[pg_starts[i] + j])
			printf("    \"marker-color\": \"%s\"%s\n", colors[pg_starts[i] + j], h_style ? "," : "")
			if(h_style)
				printf("    %s\n", styles[pg_starts[i] + j])
			printf("  }\n")
			printf("}%s\n", (pg_starts[i] + j < n_points) ? "," : "")
		}
	}
	printf("]\n")

	printf("}\n")
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
