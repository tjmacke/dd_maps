#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ extracted-address-file ]"

DD_HOME=$HOME/doordash
DD_SCRIPTS=$DD_HOME/scripts

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
		echo "ERROR: dst: $dst: qDst is empty" 1>&2
		continue
	fi
	ll="$($DD_SCRIPTS/get_latlong.sh "$qDst")"
	if [ -z "$ll" ] ; then
		LOG ERROR "get_latlong.sh failed for $qDst"
	else
		# validate what came back
		echo -e "$date\t$src\t$dst\t$qDst\t$dName\t$ll"	|\
		awk -F'\t' '{
			date = $1
			src = $2
			dst = $3
			qDst = $4
			dName = $5
			long = $7
			lat = $6
			rDst = $8

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
				r_st = 0
				for(i = 1; i <= nrf; i++){
					if(rAry[i] == qAry[1]){
						r_st = i
						break
					}
				}
				if(r_st == 0){
					err = 1
					emsg = "no street match in rDst"
				}else if(r_st + 2 > nrf){
					err = 1
					emsg = "not enough rDst after street"
				}else if(rAry[r_st+1] != qAry[2]){
					err = 1 
					emsg = "towns do not match"
				}else{
					l_qState = length(qAry[3])
					l_rState = length(rAry[r_st+2])
					if(l_rState < l_qState){
						err = 1
						emsg = "rState is too short"
					}else if(substr(rAry[r_st+2], 1, l_qState) != qAry[3]){
						err = 1
						emsg = "states do not match"
					}
				}
			}
			if(err){
				printf("ERROR: dst: %s: not found:\n", dst) > "/dev/stderr"
				printf("{\n") > "/dev/stderr"
				printf("\temsg  = %s\n", emsg) > "/dev/stderr"
				printf("\tquery = %s\n", qDst) > "/dev/stderr"
				printf("\treply = %s\n", rDst) > "/dev/stderr"
				printf("}\n") > "/dev/stderr"
			}else
				printf("%s\t%s\t%s\t%s\t%s\t%s\n", date, src, qDst, long, lat, rDst)
		}'
	fi
	sleep 5
done
