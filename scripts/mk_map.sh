#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ address-tsv-file ]"

FILE=

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

MB_KEY="$(cat ~/etc/mapbox.key)"

awk -F'\t' 'BEGIN {
	key = "'"$MB_KEY"'"
	wr_hdr = 1
}
{
	if(wr_hdr){
		wr_hdr = 0
		printf("<!DOCTYPE html>\n")
		printf("<html>\n")
		printf("<head>\n")
		printf("<meta charset=\"utf-8\"/>\n")
		printf("<meta name=\"viewport\" content=\"initial-scale=1,maximum-scale=1,user-scalable=no\"/>\n")
		printf("<title>%s</title>\n", "My Doordashes")
		printf("<script src=\"https://api.mapbox.com/mapbox.js/v2.2.2/mapbox.js\"></script>\n")
		printf("<link href=\"https://api.mapbox.com/mapbox.js/v2.2.2/mapbox.css\" rel=\"stylesheet\"/>\n")
		printf("<style>\n")
		printf("  body { margin:0; padding:0; }\n")
		printf("  #map { position:absolute; top:0; bottom:0; width:100%%; }\n")
		printf("</style>\n")
		printf("</head>\n")
		printf("<body>\n")
		printf("<div id=\"map\"></div>\n")
		printf("<script>\n")
		printf("L.mapbox.accessToken = \"%s\";\n", key)
		printf("var map = L.mapbox.map(\"map\", \"mapbox.streets\").setView([37.4377, -122.1603], 14);\n")
		printf("var geoJson = [\n")
	}
	if(NR > 1)
		printf(",\n")
	printf("{ \"type\": \"Feature\", \"geometry\": { \"type\": \"Point\", \"coordinates\": [%s, %s] }, \"properties\": { \"title\": \"src: %s<br/>dst: %s\", \"marker-color\": \"#b33\" } }", $4, $3, $1, $2)
}
END {
	if(!wr_hdr){
		printf("\n")
		printf("];\n")
		printf("var myLayer = L.mapbox.featureLayer().addTo(map);\n")
		printf("myLayer.setGeoJSON(geoJson);\n")
		printf("</script>\n")
		printf("</body>\n")
		printf("</html>\n")
	}
}' $FILE
