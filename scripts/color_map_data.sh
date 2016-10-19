#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -c conf-file ] [ -desat ] [ map-data-file ]"

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
	RD_CONFIG="$DM_LIB/rd_config.awk"
	COLOR_FUNCS="$DM_LIB/color_funcs.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	RD_CONFIG="\"$DM_LIB/rd_config.awk\""
	COLOR_FUNCS="\"$DM_LIB/color_funcs.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

CFILE=$DM_ETC/color.info
DESAT=
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
	-desat)
		DESAT="yes"
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

$AWK -F'\t' '
@include '"$RD_CONFIG"'
@include '"$COLOR_FUNCS"'
BEGIN {
	cfile = "'"$CFILE"'"
	if(rd_config(cfile, config)){
		err = 1
		exit err
	}
	for(k in config){
		split(k, keys, SUBSEP)
		if(keys[1] == "pcrange")
			pcrange[keys[2]] = config[k]
		else if(keys[1] == "stab")
			st_src[keys[2]] = config[k]
		else{
			printf("ERROR: unknown table in config file %s\n", keys[1], cfile) > "/dev/stderr"
			err = 1
			exit err
		}
	}
	if(init_crange((pcrange["start"] ":" pcrange["end"]), colorInfo)){
		err = 1;
		exit err
	}
	desat = "'"$DESAT"'" == "yes"
# Using sigmoid function desaturator
#	n_stab = asorti(st_src, st_dst, "cmp_levels")
#	for(i = 1; i <= n_stab; i++){
#		stab[i, "level"] = st_dst[i]
#		stab[i, "value"] = st_src[st_dst[i]]
#	}
#	delete st_src
#	delete st_dst
}
{
	n_points++

	dv4hue[n_points] = $1
	if(n_points == 1){
		dv4hue_min = $1
		dv4hue_max = $1
	}else if($1 < dv4hue_min)
		dv4hue_min = $1
	else if($1 > dv4hue_max)
		dv4hue_max = $1

	if(desat){
		dv4sat[n_points] = $2
		if(n_points == 1){
			dv4sat_min = $2
			dv4sat_max = $2
		}else if($2 < dv4sat_min)
			dv4sat_min = $2
		else if($2 > dv4sat_max)
			dv4sat_max = $2
	}

	label[n_points] = $(desat + 2)
	title[n_points] = $(desat + 3)
	long[n_points] = $(desat + 4)
	lat[n_points] = $(desat + 5)
}
END {
	# Check that that we of data values; if not use the start value
	h_dv_range = dv4hue_max > dv4hue_min
	if(desat)
		h_ds_range = dv4sat_max > dv4sat_min
	for(i = 1; i <= n_points; i++){
		frac = !h_dv_range ? 0 : (dv4hue[i] - dv4hue_min)/(dv4hue_max - dv4hue_min) 
		color = set_12bit_color(frac, colorInfo)
		if(desat){
			s_frac = !h_ds_range ? 1 : (dv4sat[i] - dv4sat_min)/(dv4sat_max - dv4sat_min)
			color = desat_12bit_color(color, s_frac)
		}
		printf("#%s\t%s:<br/>%s\t%s\t%s\n", color, title[i], label[i], long[i], lat[i])
	}
}
function cmp_levels(i1, v1, i2, v2) {
	if(i1 == "rest")
		return 1
	else if(i2 == "rest")
		return -1
	else
		return (i1 - i2)
}' $FILE
