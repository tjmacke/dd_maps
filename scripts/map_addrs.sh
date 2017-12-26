#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -fl flist-json ] -at { src | dst } [ address-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# TODO: fix this evil dependency
JU_HOME=$HOME/json_utils
JU_BIN=$JU_HOME/bin

TMP_XFILE=
TMP_JFILE=

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	CFG_UTILS="$DM_LIB/cfg_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	CFG_UTILS="\"$DM_LIB/cfg_utils.awk\""
else
	LOG ERROR "unsupported awk version \"$AWK_VERSION\", must be 3 or 4"
	exit 1
fi

FLIST=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-fl)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-fl requires flist-json argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		FLIST="$1"
		shift
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

rval=0

awk -F'\t' 'BEGIN {
	flist = "'"$FLIST"'"
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 2 : 3

	jfile = "'"$TMP_JFILE"'"
	if(jfile != ""){
		for(n_cbtab = 0; (getline < jfile) > 0; ){
			n_cbtab++
			cbtab[n_cbtab] = $0
		}
		close(jfile)
	}else
		n_cbtab = 0
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
	for(cb = 1; cb <= n_cbtab; cb++)
		printf("%s,\n", cbtab[cb])
	for(p = 1; p <= n_pts; p++){
		printf("{\n")
		printf("  \"type\": \"Feature\",\n")
		printf("  \"geometry\": {\"type\": \"Point\", \"coordinates\": [%.7f, %.7f]},\n", lng[p], lat[p])
		printf("  \"properties\": {\n")
		printf("    \"title\": \"%s\",\n", q_addr[p])
		printf("    \"marker-size\": \"small\",\n")
		printf("    \"marker-color\": \"#aae\"\n")
		printf("  }\n")
		printf("}%s\n", ((p < n_pts) || flist) ? "," : "")
	}
	while((getline line < flist) > 0){
		printf("%s\n", line)
	}
	close(flist)
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

if [ ! -z "$TMP_XFILE" ] ; then
	rm -f $TMP_XFILE $TMP_JFILE 
fi

exit $rval
