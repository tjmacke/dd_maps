#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] data-dir"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

TMP_PAY_FILE=/tmp/pay.$$
TMP_SRC_FILE=/tmp/src.$$
TMP_SFRESH_FILE=/tmp/sfresh.$$
TMP_DFRESH_FILE=/tmp/dfresh.$$

DIR=

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
		DIR=$1
		shift
		break
		;;
	esac
done

if [ -z "$DIR" ] ; then
	LOG ERROR "missing data-dir argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -d "$DIR" ] ; then
	LOG ERROR "data-dir $DIR does not exist or is not a directory"
	echo "$U_MSG"
	exit 1
fi

n_rfiles=$(ls $DIR/r*tsv 2> /dev/null | wc -l)
if [ $n_rfiles -eq 0 ] ; then
	LOG ERROR "data-dir $DIR has no runs-files"
	exit 1
fi

if [ ! -f $DIR/payments.*.tsv ] ; then
	LOG ERROR "data-dir $DIR has not payments-file"
	exit
fi

$DM_SCRIPTS/get_pay_rates.sh $DIR/payments.*.tsv > $TMP_PAY_FILE
cat $DIR/r*.tsv | $DM_SCRIPTS/get_new_sources.sh > $TMP_SRC_FILE
cat $DIR/r*.tsv | $DM_SCRIPTS/get_freshness_info.sh -at src -ts week > $TMP_SFRESH_FILE
cat $DIR/r*.tsv | $DM_SCRIPTS/get_freshness_info.sh -at dst -ts week > $TMP_DFRESH_FILE

Rscript $DM_LIB/plotAllStatsMain.R -p $TMP_PAY_FILE -s $TMP_SRC_FILE -sf $TMP_SFRESH_FILE -df $TMP_DFRESH_FILE

rm -f $TMP_PAY_FILE $TMP_SRC_FILE $TMP_SFRESH_FILE $TMP_DFRESH_FILE
