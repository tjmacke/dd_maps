#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -db db-file [ -d YYYYMMDD ] [ addr-geo-error-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

DM_DB=
DATE=
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
			LOG ERROR "-db requires -db-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DM_DB=$1
		shift
		;;
	-d)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-d requires date argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DATE=$1
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

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing -db db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

if [ -z "$FILE" ] ; then
	if [ -z "$DATE" ] ; then
		LOG ERROR "-d date must be specified when reading from stdin"
		exit 1
	fi
else
	f_DATE="$(echo $FILE |\
	awk -F. '{ nf = split($2, ary, "T") ; if(length(ary[1]) != 8 || ary[1] !~ /^20[12][0-9]{5}$/){ printf("BAD date: %s\n", ary[1]) }else{ printf("%s\n", ary[1]) } }')"
	if [[ $f_DATE == BAD* ]] ; then
		LOG ERROR "$f_DATE"
		exit 1
	fi
fi

if [ -z "$DATE" ] ; then
	DATE=$f_DATE
elif [ "$DATE" != "$f_DATE" ] ; then
	LOG ERROR "specified date, $DATE, does not match file date, $f_DATE"
	exit 1
fi

grep '^ERROR' $FILE	|\
awk '{
	# auto detect error format: old uses ":" for sep, new uses tab
	sep = index($0, "\t") != 0 ? "\t" : ":"
	nf = split($0, ary, sep)
	addr ary[4]
	sub(/^ */, "", addr)
	sub(/ *$/, "", addr)
	reason = ary[5]
	sub(/^ */, "", reason)
	sub(/ *$/, "", reason)
	if(reason == "not found")
		reason = "geo.fail"
	else if(substr(reason, 1, 3) == "B, "){
		reason = substr(reason, 4)
	}
	printf("%s\t%s\n", reason, addr)
}'			|\
while read line ; do
	upd_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
		date = "'"$DATE"'"
		date = sprintf("%s-%s-%s", substr(date, 1, 4), substr(date, 5, 2), substr(date, 7, 2))
	}
	{
		printf(".log stderr\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		printf("UPDATE addresses SET a_stat = %s, as_reason = %s, date_geo_checked = %s WHERE address = %s ;\n", esc_string("B"), esc_string($1), esc_string(date), esc_string($2))
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	sql_msg="$(echo -e "$upd_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ ! -z "$sql_msg" ] ; then
		err="$(echo "$sql_msg"	|\
			tail -1		|\
			awk -F: '{
				work = $(NF-1) ; sub(/^ */, "", work) ; printf("%s", work)
				work = $NF ; sub(/^ */, "", work) ; printf(": %s", work)
			}')"
		LOG ERROR "$err: $line:"
	fi
done
