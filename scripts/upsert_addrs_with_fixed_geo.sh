#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } [ addr-geo-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

if [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero sizse"
	exit 1
fi

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
		LOG ERROR "unkknown option $1"
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
while read line ; do
	addr="$(echo "$line" | awk -F'\t' '{ printf("%s\n", "'"$ATYPE"'" == "src" ? $2 : $3) }')"
	sel_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf("SELECT address_id FROM addresses WHERE address = %s ;\n", esc_string("'"$addr"'"))
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	addr_id="$(echo -e "$sel_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ -z "$addr_id" ] ; then
		q_details="$(echo -e ".\t.\t.\t.\tJob\t$addr\t." | $DM_SCRIPTS/get_addrs_from_runs_2.sh -at src | awk -F'\t' 'NR > 1{ printf("%s|%s\n", $5, $6) ; exit 0 }')"
		sql_stmt="$(echo "$line" |\
		awk -F'\t' 'BEGIN {
			apos = sprintf("%c", 39)
			split("'"$q_details"'", ary, "|")
		}
		{
			printf(".log stderr\\n")
			printf("INSERT INTO addresses (a_stat, as_reason, address, a_type, qry_address, rply_address, lng, lat) VALUES ")
			printf("(")
			printf("%s", esc_string("G"))
			printf(", %s", esc_string("geo.ok.ocg"))
			printf(", %s", esc_string("'"$addr"'"))
			printf(", %s", esc_string(ary[2]))
			printf(", %s", esc_string(ary[1]))
			printf(", %s", esc_string($6))
			printf(", %s", esc_string($4))
			printf(", %s", esc_string($5))
			printf(");")
		}
		function esc_string(str,   work) {
			work = str
			gsub(apos, apos apos, work)
			return apos work apos
		}')"
	else
		sql_stmt="$(echo "$line" |\
		awk -F'\t' 'BEGIN {
			apos = sprintf("%c", 39)
		}
		{
			printf(".log stderr\\n")
			printf("UPDATE addresses SET a_stat = %s, as_reason = %s, lng = %s, lat = %s, rply_address = %s WHERE address = %s ;\n",
				esc_string("G"), esc_string("geo.ok.ocg"), $4, $5, esc_string($6), esc_string("'"$addr"'"))
		}
		function esc_string(str,   work) {
			work = str
			gsub(apos, apos apos, work)
			return apos work apos
		}')"
		echo "$upd_stmt"
	fi
	sql_msg="$(echo -e "$sql_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ ! -z "$sql_msg" ] ; then
		err="$(echo "$sql_msg"	|\
			tail -1 |\
			awk -F: '{
				work = $(NF-1) ; sub(/^ */, "", work) ; printf("%s", work)
				work = $NF ; sub(/^ */, "", work) ; printf(": %s\n", work)
			}')"
		LOG ERROR "$err: $addr"
	fi
done
