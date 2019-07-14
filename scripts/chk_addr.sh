#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -gf geo-file.tsv ] addr"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

TMP_PFILE=/tmp/points.$$
TMP_CA_CFILE=/tmp/ca_cfile.$$
TMP_CA_CFILE_JSON=/tmp/json_file.$$
TMP_CFILE=/tmp/cfile.$$

. $DM_ETC/geocoder_defs.sh
GC_LIST="$GEO_PRIMARY,$GEO_SECONDARY,$GEO_TERTIARY"

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	CFG_UTILS="$DM_LIB/cfg_utils.awk"
	INTERP_UTILS="$DM_LIB/interp_utils.awk"
	COLOR_UTILS="$DM_LIB/color_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	CFG_UTILS="\"$DM_LIB/cfg_utils.awk\""
	INTERP_UTILS="\"$DM_LIB/interp_utils.awk\""
	COLOR_UTILS="\"$DM_LIB/color_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

GEO_FILE=
ADDR=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-gf)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-gf requires geo-file.tsv argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GEO_FILE=$1
		shift
		;;
	-*)
		LOG ERROR "unknown option $1"
		echo "$U_MSG" 1>&2
		exit 1
		;;
	*)
		ADDR="$1"
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

if [ -z "$ADDR" ] ; then
	LOG ERROR "missing addr argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

for gc in $(echo $GC_LIST | tr ',' ' ') ; do
	$DM_SCRIPTS/get_geo_for_addrs.sh -gl $gc -a "$gc: $ADDR" 2> /dev/null
done > $TMP_PFILE
if [ ! -z "$GEO_FILE" ] ; then
	cp $TMP_PFILE $GEO_FILE
fi
awk 'END {
	printf("main.scale_type = factor\n")
	printf("main.values = 0.9,0.7,0.7 | 0.7,0.9,0.7\n")
	printf("main.keys = geo | ocd\n")
	printf("main.def_value = %s\n", "0.7,0.7,0.9")
	printf("main.def_key_text = ss\n")
}' < /dev/null > $TMP_CA_CFILE
$AWK -F'\t' '
@include '"$CFG_UTILS"'
@include '"$INTERP_UTILS"'
@include '"$COLOR_UTILS"'
BEGIN {
	cfile = "'"$TMP_CA_CFILE"'"
	CFG_read(cfile, config)
	
	if(IU_init(config, color, "main")){
		printf("ERROR: BEGIN: IU_init failed\n") > "/dev/stderr"
		err = 1
		exit err
	}
}
{
	n_ary = split($2, ary, ":")
	iv = IU_interpolate(color, ary[1])
	printf("#%s\n", CU_rgb_to_24bit_color(iv))
}' $TMP_PFILE > $TMP_CFILE
$DM_SCRIPTS/cfg_to_json.sh $TMP_CA_CFILE > $TMP_CA_CFILE_JSON
$DM_SCRIPTS/map_addrs.sh -sc $TMP_CA_CFILE_JSON -cf $TMP_CFILE -at src $TMP_PFILE

rm -f $TMP_PFILE $TMP_CA_CFILE $TMP_CA_CFILE_JSON $TMP_CFILE
