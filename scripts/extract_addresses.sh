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

awk -F'\t' 'BEGIN {
	pr_hdr = 1
	pr_ba_hdr = 1
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
	abbrevs["Ct" ] = "Court"
	abbrevs["Ct." ] = "Court"
	abbrevs["Dr" ] = "Drive"
	abbrevs["Dr." ] = "Drive"
	abbrevs["Rd" ] = "Road"
	abbrevs["Rd." ] = "Road"
	abbrevs["St" ] = "Street"
	abbrevs["St." ] = "Street"
}
$5 == "Job" {
	src = $6
	dst = $7
	nf = split(dst, ary, ",")
	for(i = 1; i <= nf; i++){
		sub(/^  */, "", ary[i])
		sub(/  *$/, "", ary[i])
	}

	if(nf == 2)
		street = ary[1]
	else if(ary[nf] ~ /^CA 94305/)
		street = ary[nf - 1]
	else if(ary[nf] ~ /^CA/)
		street = ary[nf-2]
	else
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

	if(ary[nf] !~ /^CA/)
		c_dst = sprintf("%s, %s, CA", street, town)
	else
		c_dst = sprintf("%s, %s", street, town)

	if(c_dst !~ /^[1-9]/ || c_dst !~ /, CA/){
		b_dst = c_dst
		c_dst = ""
	}else
		b_dst = ""

	if(pr_hdr){
		pr_hdr = 0
		printf("%s\t%s\t%s\t%s\n", "src", "dst", "canDst", "badDst")
	}
	printf("%s\t%s\t%s\t%s\n", src, dst, c_dst, b_dst)
}
# encode apos, space
function simple_url_encoder(addr,   ix) {

	if((ix = index(addr, "+")))
		return ""

	gsub(apos, "%27", addr)
	gsub(" ", "+", addr)
	return addr
}' $FILE
