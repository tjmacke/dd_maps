#! /bin/bash
#
# this script extracts the canonicalized _dst_ address from the src/dst input pair
# the canonicalized _dst_ is NOT web safe
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ doordash-data-file ]"

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

awk -F'\t' '{
	if($5 == "Job"){
		printf("%s\t%s\n", $6, $7)
	}
}' $FILE	|\
awk -F'\t' 'BEGIN {
	apos = sprintf("%c", 39)
	pfx["Apt." ] = 1
	pfx["Bldg."] = 1
	pfx["No."  ] = 1
        pfx["Rm."  ] = 1
	pfx["Ste." ] = 1
	towns["East PA" ] = "East Palo Alto"
	towns["LAH"     ] = "Los Altos Hills"
	towns["MP"      ] = "Menlo Park"
	towns["MV"      ] = "Mountain View"
	towns["PA"      ] = "Palo Alto"
	towns["RWC"     ] = "Redwood City"
	abbrevs["Ave" ] = "Avenue"
	abbrevs["Ave."] = "Avenue"
	abbrevs["Ct." ] = "Court"
	abbrevs["Dr." ] = "Drive"
	abbrevs["Rd." ] = "Road"
	abbrevs["St." ] = "Street"
}
{
	work = $2
	nf = split(work, ary, ",")
	street = ary[nf-1]
	sub(/^  */, "", street)
	nf2 = split(street, ary2, /  */)
	if(ary2[1] in pfx){
		street = ary[nf-2]
		sub(/^  */, "", street)
	}
	for(ab in abbrevs){
		l_street = length(street)
		l_ab = length(ab)
		if(l_ab >= l_street)
			continue
		ix = l_street - l_ab + 1
		if(substr(street, ix) == ab){
			street = substr(street, 1, ix - 1) abbrevs[ab]
			break
		}
	}
	town = ary[nf]
	sub(/^  */, "", town)
	if(town in towns)
		town = towns[town]
	addr = sprintf("%s, %s, CA", street, town)
	printf("%s\t%s\t%s\n", $1, $2, addr)
#	e_addr = simple_url_encode(addr)
#	if(e_addr == "")
#		printf("ERROR: can not encode: %s\n", addr) > "/dev/stderr"
#	else
#		printf("%s\t%s\t%s\n", $1, $2, e_addr)
}
# encode apos, space
function simple_url_encode(addr) {

	if((ix = index(addr, "+")))
		return ""

	gsub(apos, "%27", addr)
	gsub(" ", "+", addr)
	return addr
}'
