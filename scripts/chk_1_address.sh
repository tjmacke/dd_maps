#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ - help ] [ -dh doordash-home ] -at { src | dst } -m month addr"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined."
	exit 1
fi
DM_SCRIPTS=$DM_HOME/scripts

ATYPE=
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

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$MONTH" ] ; then
	LOG ERROR "missing -m month argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

J_LINE="$(awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	addr = "'"$ADDR"'"
}
$5 == "Job" {
	fld = atype == "src" ? 6 : 7
	if($fld == addr){
		print $0
		exit 0
	}
}' $DD_HOME/data/runs.$MONTH.tsv)"

A_LINE="$(echo "$J_LINE" | $DM_SCRIPTS/get_addrs_from_runs.sh -at $ATYPE| tail -1)"

if [ -z "$A_LINE" ] ; then
	LOG ERROR "no $ATYPE address \"$ADDR\" in runs.$MONTH.tsv"
	exit 1
fi

Q_ADDR="$(echo "$A_LINE" | awk -F'\t' '{ print $5 }')"
if [ -z "$Q_ADDR" ] ; then
	LOG ERROR "bad address: $ADDR"
	exit 1
fi

echo -e "job\t$J_LINE"
echo -e "addr\t$ADDR"
echo -e "qaddr\t$Q_ADDR"
echo -e "candidates\t{"
echo -e "\tscore\taddress"
$DM_SCRIPTS/get_latlong.sh "$Q_ADDR"	|\
awk '{ printf("\t%s\n", $0) }'
echo "}"
