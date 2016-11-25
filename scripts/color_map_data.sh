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

	if(("_globals", "size_values") in config){
		if(IU_init(config, size, "size", "size_values", "size_breaks")){
			err = 1
			exit err
		}
		use_size = 1
	}else
		use_size = 0

	sfile = "'"$SFILE"'"
}
{
	# Rules: 
	# 1. all lines must have the same number of fields.
	# 2. number of fields must be 6 or 12 (points or lines)
	# 3. For 12 field lines, at least 1 color and 1 size must be "off", ie have value = "."
	
	if(n_fields == 0)
		n_fields = NF
	else if(NF != n_fields){
		printf("ERROR: line %d: wrong number of fields %d, must be %d\n", NR, NF, n_fields) > "/dev/stderr"
		err = 1
		exit err
	}

	n_points++
	color_data[n_points] = $1
	size_data[n_points] = $2
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
		use_color = get_data_stats(n_points, color_data, stats)
		color_data_min = stats["min"]
		color_data_max = stats["max"]
		delete stats
	}

 	# use_size at this point means we have a size interp in the config
 	if(use_size){
		use_size = get_data_stats(n_points, size_data, stats)
		size_data_min = stats["min"]
		size_data_max = stats["max"]
		delete stats
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

		# use_size at this point means we have some actual size values
		style_msg = "."
		if(use_size){
			if(size_data[i] != "."){
				mrkr_size = IU_interpolate(size, size_data[i], size_data_min, size_data_max)
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
		if(use_size){
			printf("size_min_value = %g\n", size_data_min) >> sfile
			printf("size_max_value = %g\n", size_data_max) >> sfile
			printf("size_stats = %d,%.1f", size["counts", 1], 100.0*size["counts", 1]/size["tcounts"]) >> sfile
			for(i = 2; i <= size["nvalues"]; i++)
				printf(" | %d,%.1f", size["counts", i], 100.0*size["counts", i]/size["tcounts"]) >> sfile
			printf("\n") >> sfile
		}
		close(sfile)
	}

	exit 0
}
function get_data_stats(n_data, data, d_stats,   use_data, i, d_min, d_max) {

	d_stats["use"] = 0
	use_data = 0
	for(i = 1; i <= n_data; i++){
		if(data[i] != "."){
			d_min = data[i]
			d_max = data[i]
			use_data = 1
			break
		}
	}
	if(use_data){
		for(i = 1; i <= n_data; i++){
			if(data[i] == ".")
				continue;
			if(data[i] < d_min)
				d_min = data[i]
			else if(data[i] > d_max)
				d_max = data[i]
		}
		d_stats["use"] = 1
		d_stats["min"] = d_min
		d_stats["max"] = d_max
	}
	return use_data
}' $FILE
