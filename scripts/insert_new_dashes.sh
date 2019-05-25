#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -db db-file [ breakdown-of-pay-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

TMP_DFILE=/tmp/dashes.$$

DM_DB=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-db)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-db requires db-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DM_DB=$1
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
	LOG ERROR "extra argumenst $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing -db db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

sqlite3 $DM_DB > $TMP_DFILE <<_EOF_
.mode tabs
PRAGMA foreign_keys = on ;
SELECT time_start FROM dashes ;
_EOF_

awk -F'\t' 'BEGIN {
	dfile = "'"$TMP_DFILE"'"
	for(n_dtab = 0; (getline < dfile) > 0; ){
		n_dtab++
		dtab[$0] = 1
	}
	close(dfile)
}
{
	if($1 == "date")
		next
	start_time = $1 "T" $2
	if(!(start_time in dtab))
		print $0
}' $FILE	|\
while read line ; do
	ins_stmt="$(echo "$line"	|\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		printf("INSERT INTO dashes (time_start, time_end, deliveries, hours, delivery_pay, boost_pay, tip_amount, deductions, extras, total_pay) VALUES ")
		printf("(")
		printf("%s", esc_string($1 "T" $2))
		printf(", %s", esc_string($1 "T" $3))
		printf(", %d", $4)
		printf(", %s", $5)
		printf(", %s", $6)
		printf(", %s", $7)
		printf(", %s", $8)
		printf(", %s", $9)
		printf(", %s", $10)
		printf(", %s", $11)
		printf(");\n")
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	sql_msg="$(echo -e "$ins_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ ! -z "$sql_msg" ] ; then
		dash="$(echo "$line" | awk -F'\t' '{ print $1 "T" $2 }')"
		err="$(echo "$sql_msg"	|\
			tail -1	|\
			awk -F: '{
				work = $(NF-1) ; sub(/^ */, "", work) ; printf("%s", work)
				work = $NF ; sub(/^ */, "", work) ; printf(": %s\n", work)
			}')"
		LOG ERROR "$err: $dash"
	fi
done

rm -f $TMP_DFILE
