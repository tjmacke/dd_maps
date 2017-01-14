#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] unused-addr-file"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

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

# require a file, piping seems dangerours
if [ -z "$FILE" ] ; then
	LOG ERROR "missing unused-addr-file"
	echo "$U_MSG" 1>&2
	exit 1
fi

cat $FILE	|\
while read line ; do
	del_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf("PRAGMA foreign_keys = on ;\n")
		printf("DELETE FROM addresses WHERE address = %s ;\n", esc_string($1))
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	sql_msg="$(echo -e "$del_stmt" | sqlite3 $DM_DB 2>&2)"
	if [ ! -z "$sql_msg" ] ; then
		err="$(echo "$sql_msg"	|\
		tail -1			|\
		awk -F: '{
			work = $(NF-1) ; sub(/^ */, "", work) ; printf("%s", work)
			work = $NF ; sub(/^ */, "", work) ; printf(": %s\n", work)
		}')"
		LOG ERROR "$err $line"
	fi
done
