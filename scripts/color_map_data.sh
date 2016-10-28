#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -c conf-file ] [ -v2 { desat | size } ] [ map-data-file ]"

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
	COLOR_UTILS="$DM_LIB/color_utils.awk"
	INTERP_UTILS="$DM_LIB/interp_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	RD_CONFIG="\"$DM_LIB/rd_config.awk\""
	COLOR_UTILS="\"$DM_LIB/color_utils.awk\""
	INTERP_UTILS="\"$DM_LIB/interp_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

CFILE=$DM_ETC/color.info
V2=
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
	-v2)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-v2 requires an argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		V2=$1
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

if [ ! -z "$V2" ] ; then
	if [ "$V2" != "desat" ] && [ "$V2" != "size" ] ; then
		LOG ERROR "unknown -v2 value $V2"
		echo "$U_MSG" 1>&2
		exit 1
	fi
fi 

$AWK -F'\t' '
@include '"$RD_CONFIG"'
@include '"$COLOR_UTILS"'
@include '"$INTERP_UTILS"'
BEGIN {
 	cfile = "'"$CFILE"'"
 	if(rd_config(cfile, config)){
 		err = 1
 		exit err
 	}

	if(IU_init(config, color, "color", "color_values", "color_breaks")){
		err = 1;
		exit err
	}

 	v2 = "'"$V2"'"
 	if(v2 != ""){
 		have_v2 = 1
 		desat = v2 == "desat"
 		size = v2 == "size"
 	}else
 		have_v2 = size = desat = 0

	if(size){
		if(IU_init(config, v2size, "v2size", "v2size_values", "v2size_breaks")){
			err = 1
			exit err
		}
	}

# TODO: figure out if I am going to keep this
#	if(desat){
#		if(IU_init(config, size, "size", "v2size_values", "v2size_breaks")){
#			err = 1
#			exit err
#		}
#	}

}
{
	if(NF == 5 && have_v2){
		printf("ERROR: line %d: wrong number of fields %d: need %d\n", NR, NF, 6) > "/dev/stderr"
		err = 1
		exit err
	}
	n_points++

	dv4hue[n_points] = $1
	if(n_points == 1){
		dv4hue_min = $1
		dv4hue_max = $1
	}else if($1 < dv4hue_min)
		dv4hue_min = $1
	else if($1 > dv4hue_max)
		dv4hue_max = $1

	if(have_v2){
		v2_data[n_points] = $2
	}

	labels[n_points] = $(have_v2 + 2)
	titles[n_points] = $(have_v2 + 3)
	longs[n_points] = $(have_v2 + 4)
	lats[n_points] = $(have_v2 + 5)
}
END {
	if(err)
		exit err

	if(desat || size){
		v2_data_min = v2_data[1]
		v2_data_max = v2_data[1]
		for(i = 2; i <= n_points; i++){
			if(v2_data[i] < v2_data_min)
				v2_data_min = v2_data[i]
			else if(v2_data[i] > v2_data_max)
				v2_data_max = v2_data[i]
		}
		h_ds_range = v2_data_max > v2_data_min
	}

	for(i = 1; i <= n_points; i++){
		rgb = IU_interpolate(color, dv4hue[i], dv4hue_min, dv4hue_max)
		hex_color = CU_rgb_to_24bit_color(rgb)
		style_msg = "."

# TODO: rework this
		if(desat){
			s_frac = !h_ds_range ? 1 : (v2_data[i] - v2_data_min)/(v2_data_max - v2_data_min)
#			hex_color = CU_desat_12bit_color(hex_color, s_frac)
			hex_color = CU_desat_24bit_color(hex_color, s_frac)
		}else if(size){
			mrkr_size = IU_interpolate(v2size, v2_data[i], v2_data_min, v2_data_max)
			style_msg = sprintf("\"marker-size\": \"%s\"", mrkr_size)
		}

		printf("#%s\t%s\t%s:<br/>%s\t%s\t%s\n", hex_color, style_msg, titles[i], labels[i], longs[i], lats[i])
	}
}' $FILE
