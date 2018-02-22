#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -v ] [ -c conf-file ] [ -geo geocoder ] -at { src | dst } [ extracted-address-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

LL_FILE=/tmp/ll.$$.json

TODAY="$(date +%Y-%m-%d)"

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	CFG_UTILS="$DM_LIB/cfg_utils.awk"
	ADDR_UTILS="$DM_LIB/addr_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	CFG_UTILS="\"$DM_LIB/cfg_utils.awk\""
	ADDR_UTILS="\"$DM_LIB/addr_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

VERBOSE=
AI_FILE=$DM_ETC/address.info
GEO=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-v)
		VERBOSE="yes"
		shift
		;;
	-c)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-c requires conf-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		AI_FILE=$1
		shift
		;;
	-geo)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-geo requires geocoder argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GEO=$1
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

if [ ! -z "$GEO" ] ; then
	GEO="-geo $GEO"
fi

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

lcnt=0
cat $FILE	|\
while read line ; do
	lcnt=$((lcnt+1))
	# skip the header
	if [ $lcnt -eq 1 ] ; then
		continue
	elif [ $lcnt -gt 2 ] ; then
		sleep 5
	fi
	astat="$(echo "$line" | awk -F'\t' '{ print $1 ~ /^B/ ? "bad" : "good" }')"
	if [ "$astat" == "bad" ] ; then
		echo "$line" |\
		awk -F'\t' 'BEGIN {
			atype = "'"$ATYPE"'"
		}
		{
			printf("ERROR: %s: addr: %s: %s\n", $2, atype == "src" ? $3 : $4, $1)
		}' 1>&2
		continue
	fi
	src="$(echo "$line" | awk -F'\t' '{ print $3 }')"
	dst="$(echo "$line" | awk -F'\t' '{ print $4 }')"
	query="$(echo "$line" | awk -F'\t' '{ print $5 }')"
	name="$(echo "$line" | awk -F'\t' '{ print $6 }')"
	$DM_SCRIPTS/get_latlong.sh -limit 20 $GEO "$query" > $LL_FILE
	if [ ! -s $LL_FILE ] ; then
		LOG ERROR "get_latlong.sh failed for $query"
	else
		# validate what came back
		$AWK -F'\t' '
		@include '"$CFG_UTILS"'
		@include '"$ADDR_UTILS"'
		BEGIN {
			today = "'"$TODAY"'"

			verbose = "'"$VERBOSE"'" == "yes"
			atype = "'"$ATYPE"'"
			geo = "'"$GEO"'"
			if(geo != ""){
				split(geo, ary, /  */)
				geo = ary[2]
			}
			src = "'"$src"'"
			dst = "'"$dst"'"
			addr = atype == "src" ? src : dst
			query = "'"$query"'"
			name = "'"$name"'"

			ai_file = "'"$AI_FILE"'"
			if(CFG_read(ai_file, addr_info)){
				err = 1
				exit err
			}

			# check that we got all the data we need
			ad_counts["n_us_states"] = AU_get_addr_data(addr_info, "us_states", us_states)
		 
			ad_counts["n_towns_a2q"] = AU_get_addr_data(addr_info, "towns_a2q", towns_a2q)
			ad_counts["n_st_types_2qry"] = AU_get_addr_data(addr_info, "st_types_2qry", st_types_2qry)
			ad_counts["n_dirs_2qry"] = AU_get_addr_data(addr_info, "dirs_2qry", dirs_2qry)
			ad_counts["n_ords_2qry"] = AU_get_addr_data(addr_info, "ords_2qry", ords_2qry)
		 
			ad_counts["n_towns_r2q"] = AU_get_addr_data(addr_info, "towns_r2q", towns_r2q)
		 
			for(ad in ad_counts){
				if(ad_counts[ad] == 0){
					printf("ERROR: %s no \"%s\" data\n", ai_file, substr(ad, 3)) > "/dev/stderr"
					err = 1
				}
			}
			if(err)
				exit err

			# create a map of full state names
			for(s in us_states)
				us_states_long[us_states[s]] = s

			# split the input address into fields. No need to test, as it must be good to get here
			pq_options["rply"] = 0
			pq_options["do_subs"] = 1
			pq_options["no_name"] = "Residence"
			AU_parse(pq_options, addr, addr_ary, us_states, us_states_long, towns_a2q, st_types_2qry, dirs_2qry, ords_2qry)

			pr_options["rply"] = 1
			# TODO: this will need to be generalized!
			pr_options["us_only"] = geo == "" || geo == "geo"
			pr_options["do_subs"] = 1
			pr_options["no_name"] = ""
		}
		{
			if(AU_parse(pr_options, $2, rply_ary, us_states, us_states_long, towns_r2q, st_types_2qry, dirs_2qry, ords_2qry)){
				n_lines++
				lines[n_lines] = sprintf("reply = %s", $2)
				n_lines++
				lines[n_lines] = sprintf("emsg  = %s", rply_ary["emsg"])
				err = 1
			}else{
				# get the match score, retain the first of the highest
				mt_options["verbose"] = verbose
				mt_options["ign_zip"] = 1
				mt_options["no_name"] = "Residence"
				m_score = AU_match(mt_options, addr_ary, rply_ary)
				if(m_score > 0){
					if(m_score > b_score){
						b_score = m_score
						b_match = sprintf("%s\t%s\t%s\t%s\t%s\t%s", today, src, dst, $4, $3, $2)
					}
				}else{
					n_lines++
					lines[n_lines] = sprintf("reply = %s", $2)
					n_lines++
					lines[n_lines] = sprintf("emsg  = %s\t%s", rply_ary["emsg"], $0)
					err = 1
				}
			}
		}
		END {
			if(b_match != ""){
				printf("%s\n", b_match)
				err = 0
			}else if(err && n_lines > 0){
				printf("ERROR: %s: addr: %s: not found:\n", today, addr) > "/dev/stderr"
				printf("{\n") > "/dev/stderr"
				printf("\tquery = %s\n", query) > "/dev/stderr"
				for(i = 1; i <= n_lines; i++)
					printf("\t%s\n", lines[i]) > "/dev/stderr"
				printf("}\n") > "/dev/stderr"		
			}
			exit err
		}' $LL_FILE
	fi
done

rm -f $LL_FILE
