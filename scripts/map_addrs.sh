#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } [ address-file ]"

ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 2 : 3
}
{
	n_pts++
	date[n_pts] = $1
	q_addr[n_pts] = $f_addr
	lng[n_pts] = $4
	lat[n_pts] = $5
	r_addr[n_pts] = $6
}
END {
	if(n_pts == 0)
		exit 0

	pr_header()
	for(p = 1; p <= n_pts; p++){
		printf("{\n")
		printf("  \"type\": \"Feature\",\n")
		printf("  \"geometry\": {\"type\": \"Point\", \"coordinates\": [%.7f, %.7f]},\n", lng[p], lat[p])
		printf("  \"properties\": {\n")
		printf("    \"title\": \"%s\",\n", q_addr[p])
		printf("    \"marker-size\": \"small\",\n")
		printf("    \"marker-color\": \"#aae\"\n")
		printf("  }\n")
		printf("}%s\n", p < n_pts ? "," : "")
	}
	pr_trailer()
	exit 0
}
function pr_header() {

	printf("{\n")
	printf("\"geojson\": {\n")
	printf("\"type\": \"FeatureCollection\",\n")
	printf("\"metadata\": {\n")
	printf("  \"generated\": \"%s\",\n", strftime("%Y%m%dT%H%M%S%Z"))
	printf("  \"title\": \"geo check\",\n" )
	printf("  \"count\": %d\n", n_pts)
	printf("},\n")
	printf("\"features\": [\n")
}
function pr_trailer() {
	printf("]\n")
	printf("}\n")
	printf("}\n")
}' $FILE
