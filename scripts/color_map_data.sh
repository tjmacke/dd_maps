#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -c conf-file [ -stats stats-file ] [ map-data-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

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

SFILE=
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
	-stats)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-stats requires stats-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		SFILE=$1
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

if [ -z "$CFILE" ] ; then
	LOG ERROR "missing -c config-file argument"
	echo "$U_MSG" 1>&2
	exit 1
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

	if(("_globals", "color_values") in config){
		if(IU_init(config, color, "color", "color_values", "color_breaks")){
			err = 1;
			exit err
		}
		use_color = 1
	}else
		use_color = 0

	if(("_globals", "v2_values") in config){
		if(IU_init(config, v2, "v2", "v2_values", "v2_breaks")){
			err = 1
			exit err
		}
		use_v2 = 1
	}else
		use_v2 = 0

	sfile = "'"$SFILE"'"
}
{
	# TODO: allow for a mix of lengths?
	n_points++
	color_data[n_points] = $1
	v2_data[n_points] = $2
	labels[n_points] = $3
	titles[n_points] = $4
	longs[n_points] = $5
	lats[n_points] = $6
}
END {
	if(err)
		exit err

	# use_color at this point means we have a color interp in the config
	if(use_color){
		use_color = 0
		for(i = 1; i <= n_points; i++){
			if(color_data[i] != "."){
				color_data_min = color_data[i]
				color_data_max = color_data[i]
				use_color = 1
				break
			}
		}
		if(use_color){
			for(i = 1; i <= n_points; i++){
				if(color_data[i] == ".")
					continue;
				if(color_data[i] < color_data_min)
					color_data_min = color_data[i]
				else if(color_data[i] > color_data_max)
					color_data_max = color_data[i]
			}
		}
	}

	# use_v2 at this point means we have a v2 interp in the config
	if(use_v2){
		use_v2 = 0
		for(i = 1; i <= n_points; i++){
			if(v2_data[i] != "."){
				v2_data_min = v2_data[1]
				v2_data_max = v2_data[1]
				use_v2 = 1
				break;
			}
		}
		if(use_v2){
			for(i = 1; i <= n_points; i++){
				if(v2_data[i] == ".")
					continue;
				if(v2_data[i] < v2_data_min)
					v2_data_min = v2_data[i]
				else if(v2_data[i] > v2_data_max)
					v2_data_max = v2_data[i]
			}
		}
	}

	for(i = 1; i <= n_points; i++){
		# use_color at this point means we have some actual color values
		hex_color = "#FFE4E1"
		if(use_color){
			if(color_data[i] != "."){
				rgb = IU_interpolate(color, color_data[i], color_data_min, color_data_max)
				# TODO: figure out whehter CU_ should return #XXX or #XXXXXX
				hex_color = "#" CU_rgb_to_24bit_color(rgb)
			}
		}

		# use_v2 at this point means we have some actual v2 values
		style_msg = "."
		if(use_v2){
			if(v2_data[i] != "."){
				mrkr_size = IU_interpolate(v2, v2_data[i], v2_data_min, v2_data_max)
				style_msg = sprintf("\"marker-size\": \"%s\"", mrkr_size)
			}
		}

		printf("%s\t%s\t%s:<br/>%s\t%s\t%s\n", hex_color, style_msg, titles[i], labels[i], longs[i], lats[i])
	}

	if(sfile != ""){
		if(use_color){
			printf("color_min_value = %g\n", color_data_min) >> sfile
			printf("color_max_value = %g\n", color_data_max) >> sfile
			printf("color_stats = %d,%.1f", color["counts", 1], 100.0*color["counts", 1]/color["tcounts"]) >> sfile
			for(i = 2; i <= color["nvalues"]; i++)
				printf(" | %d,%.1f", color["counts", i], 100.0*color["counts", i]/color["tcounts"]) >> sfile
			printf("\n") >> sfile
		}
		if(use_v2){
			printf("v2_min_value = %g\n", v2_data_min) >> sfile
			printf("v2_max_value = %g\n", v2_data_max) >> sfile
			printf("v2_stats = %d,%.1f", v2["counts", 1], 100.0*v2["counts", 1]/v2["tcounts"]) >> sfile
			for(i = 2; i <= v2["nvalues"]; i++)
				printf(" | %d,%.1f", v2["counts", i], 100.0*v2["counts", i]/v2["tcounts"]) >> sfile
			printf("\n") >> sfile
		}
		close(sfile)
	}

	exit 0
}' $FILE
