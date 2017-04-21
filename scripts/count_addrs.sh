#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -at { src | dst } [ runs-file ]"

ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
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

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

cat $FILE	|\
awk -F'\t' 'BEGIN { 
	f_atype = "'"$ATYPE"'" == "src" ? 6 : 7
}
$5 == "Job" { print $f_atype }'		|\
sort					|\
uniq -c					|\
sort -k 1rn,1				|\
awk '{
	work = $0
	sub(/^  */, "", work)
	sub(/  */, "\t", work)
	split(work, ary, "\t")
	n_lines++
	total += ary[1]
	counts[n_lines] = ary[1]
	addrs[n_lines] = ary[2]
}
END {
	printf("%s\t%s\t%s\t%s\t%s\n", "Rank", "Count", "Pct", "cumPct", "Addrees")
	r_total = 0
	for(i = 1; i <= n_lines; i++){
		r_total += counts[i]
		printf("%d\t%d\t%.3f\t%.3f\t%s\n", i, counts[i], 100.0*counts[i]/total, 100.0*r_total/total, addrs[i])
	}
}'
