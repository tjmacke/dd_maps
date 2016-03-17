#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ - help ] [ -dh doordash-home ] -m month addr"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined."
	exit 1
fi
DM_SCRIPTS=$DM_HOME/scripts

DD_HOME=
MONTH=
ADDR=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-dh)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-dh requires doordash-home argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DD_HOME=$1
		shift
		;;
	-m)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-m requires month (as YYYYMMDD) argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		MONTH=$1
		shift
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

if [ -z "$DD_HOME" ] ; then
	LOG ERROR "DD_HOME is not defined."
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$MONTH" ] ; then
	LOG ERROR "missing -m month argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

J_LINE="$(awk -F'\t' 'BEGIN {
	addr = "'"$ADDR"'"
}
$5 == "Job" {
	if($7 == addr){
		print $0
		exit 0
	}
}' $DD_HOME/data/runs.$MONTH.tsv)"

A_LINE="$(echo "$J_LINE" | $DM_SCRIPTS/get_addresses.sh		|\
tail -1)"

if [ -z "$A_LINE" ] ; then
	LOG ERROR "no address '$ADDR' in runs.$MONTH.tsv"
	exit 1
fi

echo -e "addr\t$ADDR"
echo -e "job\t$J_LINE"
echo -e "candidates\t{"
echo -e "\tscore\taddress"
Q_ADDR="$(echo "$A_LINE" | awk -F'\t' '{ print $5 }')"
$DM_SCRIPTS/get_latlong.sh "$Q_ADDR"	|\
awk '{ printf("\t%s\n", $0) }'
echo "}"
