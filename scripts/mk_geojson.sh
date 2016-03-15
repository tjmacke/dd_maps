#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -pf prop-file ] [ -pcr prop-color-range (as r,g,b:r,g,b r,g,b in [0,1]) ] [ -pn prop-name ][ resolved-address-file ]"

NOW=
PFILE=
PCRANGE="1,0.8,0.8:1,0,0"
PNAME=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-pf)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-cf requires color-by-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		PFILE=$1
		shift
		;;
	-pcr)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-cr requires color-range argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		PCRANGE="$1"
		shift
		;;
	-pn)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-cn requires color-name argument"
			echo "$U_MSG"
			exit 1
		fi
		PNAME="$1"
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

awk -F'\t' 'BEGIN {
	pfile = "'"$PFILE"'"
	n_pvals = 0
	if(pfile != ""){
		for( ; (getline < pfile) > 0; ){
			n_pvals++
			pv = $1 + 0
			pvals[n_pvals] = pv
			if(n_pvals == 1){
				min_pval = pv
				max_pval = pv
			}else if(pv < min_pval)
				min_pval = pv
			else if(pv > max_pval)
				max_pval = pv
		}
		close(pfile)
		printf("INFO: pfile: %s: %d values: max = %.3f, min = %.3f\n", pfile, n_pvals, min_pval, max_pval) > "/dev/stderr"
	}

	pcrange = "'"$PCRANGE"'"
	if(pcrange == ""){
		colorInfo["R_start"] = 1.0
		colorInfo["G_start"] = 0.8
		colorInfo["B_start"] = 0.8

		colorInfo["R_end"  ] = 1.0
		colorInfo["G_end"  ] = 0.0
		colorInfo["B_end"  ] = 0.0
	}else if(init_crange(pcrange, colorInfo)){
		err = 1
		exit err
	}

	pname = "'"$PNAME"'"
	if(pname == "")
		pname == "property"
}
{
	n_dashes++
	date[n_dashes] = $1
	#  date is the default color-by-value
	if(n_pvals == 0){
		if(min_date == "")
			min_date = $1
		else if($1 < min_date)
			min_date = $1
		if(max_date == "")
			max_date = $1
		else if($1 > max_date)
			max_date = $1
	}
	src[n_dashes] = $2
	dst[n_dashes] = $3
	lat[n_dashes] = $5
	lng[n_dashes] = $4
}
END {
	if(err)
		exit err

	# color by date 
	if(n_pvals == 0){
		work = min_date
		gsub(/-/, " ", work)
		t_min = mktime(work " 00 00 00")

		work = max_date
		gsub(/-/, " ", work)
		t_max = mktime(work " 00 00 00")
	}
	
	for(d = 1; d <= n_dashes; d++){
		if(d == 1)
			printf("[\n")
		printf("{ ")
		printf("\"type\": \"Feature\", ")
		printf("\"geometry\": { ")
		printf("\"type\": \"Point\", ")
		printf("\"coordinates\": [%s, %s]", lng[d]5, lat[d])
		printf(" }, ")
		printf("\"properties\": { ")
		printf("\"date\": \"%s\", ", date[d])
		title = sprintf("src: %s\\ndst: %s\\ndate: %s", src[d], dst[d], date[d])
		if(n_pvals > 0){
			title = title sprintf("\\n%s: %g", pname, 1.0*pvals[d])
		}
		#printf("\"title\": \"src: %s\\ndst: %s\\ndate: %s\", ", src[d], dst[d], date[d])
		printf("\"title\": \"%s\",", title)

		if(n_pvals == 0){
			work = date[d]
			gsub(/-/, " ", work)
			frac = (t_max == t_min) ? 1 : (mktime(work " 00 00 00") - t_min)/(t_max - t_min)
		}else if(min_pval == max_pval)
			frac = 1.0
		else
			frac = 1.0 * pvals[d]/(max_pval - min_pval)
		color = set_color_15(frac, colorInfo)

		printf("\"marker-color\": \"#%s\"", color)
		printf(" }")
		printf(" }%s\n", d < n_dashes ? "," : "")

		if(d == n_dashes)
			printf("]\n")
	}
}
function init_crange(crange, colorInfo,   nf, ary, R, G, B) {
	nf = split(crange, ary, ":")
	if(nf != 2){
		printf("ERROR: bad color range: %s, must be r,g,b:r,g,b r,g,b in [0,1]\n", crange) > "/dev/stderr"
		return 1
	}

	# get start color
	nf2 = split(ary[1], ary2, ",")
	if(nf2 != 3){
		printf("ERROR: bad start color: %s, must be r,g,b r,g,b in [0,1]\n", ary[1]) > "/dev/stderr"
		return 1
	}
	R = ary2[1]
	if(R < 0 || R > 1){
		printf("ERROR: bad start R value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[1]) > "/dev/stderr"
		return 1
	}
	G = ary2[2]
	if(G < 0 || G > 1){
		printf("ERROR: bad start G value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[2]) > "/dev/stderr"
		return 1
	}
	B = ary2[3]
	if(B < 0 || B > 1){
		printf("ERROR: bad start B value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[3]) > "/dev/stderr"
		return 1
	}
	colorInfo["R_start"] = R
	colorInfo["G_start"] = G
	colorInfo["B_start"] = B

	# get end color
	nf2 = split(ary[2], ary2, ",")
	if(nf2 != 3){
		printf("ERROR: bad end color: %s, must be r,g,b r,g,b in [0,1]\n", ary[2]) > "/dev/stderr"
		return 1
	}
	R = ary2[1]
	if(R < 0 || R > 1){
		printf("ERROR: bad end R value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[1]) > "/dev/stderr"
		return 1
	}
	G = ary2[2]
	if(G < 0 || G > 1){
		printf("ERROR: bad end G value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[2]) > "/dev/stderr"
		return 1
	}
	B = ary2[3]
	if(B < 0 || B > 1){
		printf("ERROR: bad end B value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[3]) > "/dev/stderr"
		return 1
	}
	colorInfo["R_end"] = R
	colorInfo["G_end"] = G
	colorInfo["B_end"] = B

	return 0
}
function set_color_15(val, colorInfo,    range, R, G, B) {

	R = int((colorInfo["R_start"] * (1 - frac) + frac * colorInfo["R_end"])/(1.0/15) + 0.5)
	G = int((colorInfo["G_start"] * (1 - frac) + frac * colorInfo["G_end"])/(1.0/15) + 0.5)
	B = int((colorInfo["B_start"] * (1 - frac) + frac * colorInfo["B_end"])/(1.0/15) + 0.5)

	return sprintf("%x%x%x", R, G, B)
}' $FILE
