#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ extracted-address-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# TODO: get_latlong.sh will eventually return > 1 addresss, as even the top rated can be wrong, so put the results in a file
LL_FILE=/tmp/ll.$$.json


# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	RD_CONFIG="$DM_LIB/rd_config.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	RD_CONFIG="\"$DM_LIB/rd_config.awk\""
else
	LOG ERROR "bad AWK_VERSION: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

CFILE=$DM_ETC/address.info

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

lcnt=0
cat $FILE	|\
while read line ; do
	lcnt=$((lcnt+1))
	# skip the header
	if [ $lcnt -eq 1 ] ; then
		continue
	fi
	date="$(echo "$line" | awk -F'\t' '{ print $2 }')"
	src="$(echo "$line" | awk -F'\t' '{ print $3 }')"
	dst="$(echo "$line" | awk -F'\t' '{ print $4 }')"
	qDst="$(echo "$line" | awk -F'\t' '{ print $5 }')"
	dName="$(echo "$line" | awk -F'\t' '{ print $6 }')"
	if [ -z "$qDst" ] ; then
		echo "ERROR: $date: dst: $dst: queryDst is empty" 1>&2
		continue
	fi
	$DM_SCRIPTS/get_latlong.sh "$qDst" > $LL_FILE
	if [ ! -s $LL_FILE ] ; then
		LOG ERROR "get_latlong.sh failed for $qDst"
	else
		# validate what came back
		$AWK -F'\t' '
		@include '"$RD_CONFIG"'
		BEGIN {
			cfile = "'"$CFILE"'"
			if(rd_config(cfile, config)){
				err = 1
				exit err
			}
			for(k in config){
				split(k, keys, SUBSEP)
				if(keys[1] == "st_abbrevs")
					st_abbrevs[keys[2]] = config[k]
				else if(keys[1] == "dirs")
					dirs[keys[2]] = config[k]
			}
		}
		{
			date = "'"$date"'"
			src = "'"$src"'"
			dst = "'"$dst"'"
			qDst = "'"$qDst"'"
			dName = "'"$dName"'"

			conf = $1
			rDst = $2
			lat = $3
			long = $4

			nqf = split(qDst, qAry, ",")
			for(i = 1; i <= nqf; i++){
				sub(/^  */, "", qAry[i])
				sub(/  *$/, "", aQry[i])
			}

			nrf = split(rDst, rAry, ",")
			for(i = 1; i <= nrf; i++){
				sub(/^  */, "", rAry[i])
				sub(/  *$/, "", rAry[i])
			}

			err = 0
			if(nrf < nqf){
				err = 1
				emsg = "rDst is shorter that qDst"
			}else{
				# qAry[1,2,3] are the street, town and st (w/o zip)
				# find the street, expand any abbrevs, then start matching
				r_st = 0
				for(i = 1; i <= nrf; i++){
					if(substr(rAry[i], 1, 1) ~ /[1-9]/){
						r_st = i
						rAry[r_st] = fix_street(rAry[r_st], st_abbrevs, dirs)
						break
					}
				}
				if(r_st == 0){
					err = 1
					emsg = "no street in replyDst"
				}else if(r_st + 2 > nrf){
					err = 1
					emsg = "not enough rDst after street"
				}else if(rAry[r_st] != qAry[1]){
					err = 1
					emsg = "streets do not match"
				}else if(rAry[r_st+1] != qAry[2]){
					err = 1 
					emsg = "towns do not match"
				}else{
					l_qState = length(qAry[3])
					l_rState = length(rAry[r_st+2])
					if(l_rState < l_qState){
						err = 1
						emsg = "replyState is too short"
					}else if(substr(rAry[r_st+2], 1, l_qState) != qAry[3]){
						err = 1
						emsg = "states do not match"
					}else{
						# if we get here, we matched the reply to query
					}
				}
			}
			if(!err){
				printf("%s\t%s\t%s\t%s\t%s\t%s\n", date, src, qDst, long, lat, rDst)
				exit 0
			}
		}
		END {
			if(err){
				printf("ERROR: %s: dst: %s: not found:\n", date, dst) > "/dev/stderr"
				printf("{\n") > "/dev/stderr"
				printf("\temsg  = %s\n", emsg) > "/dev/stderr"
				printf("\tquery = %s\n", qDst) > "/dev/stderr"
				printf("\treply = %s\n", rDst) > "/dev/stderr"
				printf("}\n") > "/dev/stderr"
			}
		}
		function fix_street(str, st_abbrevs, dirs,    nw, words, i, work, w) {
			nw = split(str, words, " ")
			work = ""
			for(i = 1; i <= nw; i++){
				if(words[i] in dirs)
					w = dirs[words[i]]
				else if(words[i] in st_abbrevs)
					w = st_abbrevs[words[i]]
				else if(words[i] == "el")
					w = "El"
				else
					w = words[i]
				work = work == "" ? w : work " " w
			}
			return work
		}' $LL_FILE
	fi
	sleep 5
done

rm -f $LL_FILE
