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
	src="$(echo "$line" | awk -F'\t' '{ print $1 }')"
	dst="$(echo "$line" | awk -F'\t' '{ print $2 }')"
	q_dst="$(echo "$line" | awk -F'\t' '{ print $3 }')"
	ll="$($DD_SCRIPTS/get_latlong.sh "$q_dst")"
	if [ -z "$ll" ] ; then
		LOG ERROR "get_latlong.sh failed for $q_dst"
	else
		# validate what came back
		echo -e "$src\t$dst\t$q_dst\t$ll"	|\
		awk -F'\t' '{
			src = $1
			dst = $2
			q_dst = $3
			long = $4
			lat = $5
			r_dst = $6
			if(index(r_dst, q_dst))
				printf("%s\t%s\t%s\t%s\t%s\n", src, q_dst, long, lat, r_dst)
			else{
				printf("ERROR: dst: %s: not found:\n", dst) > "/dev/stderr"
				printf("{\n") > "/dev/stderr"
				printf("\tquery = %s\n", q_dst) > "/dev/stderr"
				printf("\treply = %s\n", r_dst) > "/dev/stderr"
				printf("}\n") > "/dev/stderr"
			}
		}'
	fi
	sleep 5
done
