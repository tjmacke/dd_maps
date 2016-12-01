#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] address"

DM_SCRIPTS=$DM_HOME/scripts

ATYPE="src"
TODAY="$(date +%Y-%m-%d)"

ADDR=

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
		ADDR="$1"
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

if [ -z "$ADDR" ] ; then
	LOG ERROR "missing address argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

Q_ADDR="$(echo -e "$TODAY\t.\t.\t.\tJob\t$ADDR\t." | $DM_SCRIPTS/get_addrs_from_runs.sh -at $ATYPE | tail -1 | awk -F'\t' '{ printf("%s\n", $1 ~ /^B/ ? $0 : $5) }')"
a_stat="$(echo "$Q_ADDR" | awk -F'\t' '{ printf("%s\n", NF == 1 ? "G" : $1)}')"
if [ "$a_stat" != "G" ] ; then
	LOG ERROR "bad address: $ADDR: a_stat: $a_stat"
	exit 1
fi

echo -e "addr\t$ADDR"
echo -e "qaddr\t$Q_ADDR"
echo -e "candidates\t{"
$DM_SCRIPTS/get_latlong.sh "$Q_ADDR"	|\
awk '{ printf("\t%s\n", $0) }'
echo "}"
