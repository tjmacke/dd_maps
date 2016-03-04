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
	date="$(echo "$line" | awk -F'\t' '{ print $1 }')"
	src="$(echo "$line" | awk -F'\t' '{ print $2 }')"
	dst="$(echo "$line" | awk -F'\t' '{ print $3 }')"
	q_dst="$(echo "$line" | awk -F'\t' '{ print $4 }')"
	if [ -z "$q_dst" ] ; then
		echo "ERROR: dst: $dst: q_dst is empty" 1>&2
		continue
	fi
	ll="$($DD_SCRIPTS/get_latlong.sh "$q_dst")"
	if [ -z "$ll" ] ; then
		LOG ERROR "get_latlong.sh failed for $q_dst"
	else
		# validate what came back
		echo -e "$date\t$src\t$dst\t$q_dst\t$ll"	|\
		awk -F'\t' '{
			date = $1
			src = $2
			dst = $3
			q_dst = $4
			long = $5
			lat = $6
			r_dst = $7
			# this is way too simple
			if(index(r_dst, q_dst))
				printf("%s\t%s\t%s\t%s\t%s\t%s\n", date, src, q_dst, long, lat, r_dst)
			else{
				printf("ERROR: dst: %s: not found:\n", dst) > "/dev/stderr"
				printf("{\n") > "/dev/stderr"
				printf("\tquery = %s\n", q_dst) > "/dev/stderr"
				printf("\treply = %s\n", r_dst) > "/dev/stderr"
				printf("}\n") > "/dev/stderr"
			}
			# Instead 
			# split the r_dst, q_dst on , 
			# trim trailing ' '
			# for r_dst, expand street abbreviations
			# match the fields of q_dst to those in r_dst
			# Must match fiekd 1, the street
			# Must match 1 of town + state pfx or state + zip
		}'
	fi
	sleep 5
done
