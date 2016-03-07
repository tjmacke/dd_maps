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
	apos = sprintf("%c", 39)

	dirs["E"] = "East"
	dirs["N"] = "North"
	dirs["S"] = "South"
	dirs["W"] = "West"

	st_abbrevs["Ave" ] = "Avenue"
	st_abbrevs["Ave."] = "Avenue"
	st_abbrevs["Ct" ] = "Court"
	st_abbrevs["Ct." ] = "Court"
	st_abbrevs["Dr" ] = "Drive"
	st_abbrevs["Dr." ] = "Drive"
	st_abbrevs["Rd" ] = "Road"
	st_abbrevs["Rd." ] = "Road"
	st_abbrevs["St" ] = "Street"
	st_abbrevs["St." ] = "Street"

	unit["Apt." ] = 1
	unit["Bldg."] = 1
	unit["Class"] = 1
	unit["class"] = 1
	unit["Floor"] = 1
	unit["floor"] = 1
	unit["No."  ] = 1
	unit["no."  ] = 1
        unit["Rm."  ] = 1
	unit["Ste." ] = 1
	unit["Unit" ] = 1

	towns["East PA" ] = "East Palo Alto"
	towns["LAH"     ] = "Los Altos Hills"
	towns["MP"      ] = "Menlo Park"
	towns["MV"      ] = "Mountain View"
	towns["PA"      ] = "Palo Alto"
	towns["RWC"     ] = "Redwood City"
}
$5 == "Job" {
	date = $1
	src = $6
	dst = $7

	nf = split(dst, ary, ",")
	for(i = 1; i <= nf; i++){
		sub(/^  */, "", ary[i])
		sub(/  *$/, "", ary[i])
	}

	if(nf == 2){
		street = ary[1]
		town = ary[2]
	}else if(ary[nf] ~ /^CA 94305/){
		street = ary[nf - 1]
		town = ary[nf]
	}else if(ary[nf] ~ /^CA/){
		street = ary[nf-2]
		town = ary[nf-1]
	}else{
		street = ary[nf-1]
		town = ary[nf]
	}

	# If the street address was followed by a unit: bldg, no, etc
	# the actual street was the previous field
	nf2 = split(street, ary2, /  */)
	if(ary2[1] in unit){
		street = ary[nf-2]
	}else if(substr(ary2[1], 1, 1) == "#"){
		street = ary[nf-2]
	}

	# replace all st type abbreviations with their long forms
	for(ab in st_abbrevs){
		l_street = length(street)
		l_ab = length(ab)
		if(l_ab >= l_street)
			continue
		ix = l_street - l_ab + 1
		if(substr(street, ix) == ab){
			street = substr(street, 1, ix - 1) st_abbrevs[ab]
			break
		}
	}

	# replace any direction abbreviations with their long forms
	nf2 = split(street, ary2, /  */)
	work = ""
	for(i = 1; i <= nf2; i++){
		w2 = ary2[i] in dirs ? dirs[ary2[i]] : ary2[i]
		work = work == "" ? w2 : work " " w2
	}
	street = work

	town = ary[nf]
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
		printf("%s\t%s\t%s\t%s\t%s\n", "date", "src", "dst", "canDst", "badDst")
	}
	printf("%s\t%s\t%s\t%s\t%s\n", date, src, dst, c_dst, b_dst)
}
# encode apos, space
function simple_url_encoder(addr,   ix) {

	if((ix = index(addr, "+")))
		return ""

	gsub(apos, "%27", addr)
	gsub(" ", "+", addr)
	return addr
}' $FILE
