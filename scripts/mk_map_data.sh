#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -pn prop-name [ -pcr prop-color-range (as r,g,b:r,g,b r,g,b in [0,1]) ] [ address-data-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	COLOR_FUNCS="$DM_LIB/color_funcs.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	COLOR_FUNCS="\"$DM_LIB/color_funcs.awk\""
else
	LOG ERROR "bad AWK_VERSION: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

PNAME=
PCRANGE="1,0.8,0.8:1,0,0"
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-pn)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-pn requires prop-name argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		PNAME=$1
		shift
		;;
	-pcr)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-pcr requires color-range argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		PCRANGE="$1"
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

if [ -z "$PNAME" ] ; then
	LOG ERROR "missing -pn prop-name argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' '
@include '"$COLOR_FUNCS"'
BEGIN {
	pname = "'"$PNAME"'"
	pcrange = "'"$PCRANGE"'"
	if(init_crange(pcrange, colorInfo)){
		err = 1
		exit 
	}
}
{
	n_addr++

	pc = $1
	pv = $2 + 0
	if(n_addr == 1){
		min_pval = pv
		max_pval = pv
	}else if(pv < min_pval)
		min_pval = pv
	else if(pv > max_pval)
		max_pval = pv

	pcnt[n_addr] = pc
	pval[n_addr] = pv
	addr[n_addr] = $3
	long[n_addr] = $4
	lat[n_addr] = $5
}
END {
	if(err)
		exit err

	for(i = 1; i <= n_addr; i++){
		frac = pval[i]/max_pval
		color = set_4bit_color(frac, colorInfo)
		title = sprintf("src: %s\\n%s: %d, %.1f", addr[i], pname, pcnt[i], pval[i])
		if(i == 1)
			printf("[\n")
		printf("{\n")
		printf("  \"type\": \"Feature\",\n")
		printf("  \"geometry\": {")
		printf("\"type\": \"Point\", ")
		printf("\"coordinates\": [%s, %s]", long[i], lat[i])
		printf("},\n")
		printf("  \"properties\": {\n")
		printf("    \"title\": \"%s\",\n", title)
		printf("    \"marker-color\": \"#%s\"\n", color)
		printf("  }\n")
		printf("}%s\n", i == n_addr ? "" : ",")
		if(i == n_addr)
			printf("]\n")
	}
}' $FILE
