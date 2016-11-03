#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -at { src | dst } [ addr-nogeo-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "$DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

if [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
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
		LOG ERROR "unknown option $*"
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
	LOG ERROR "unknown addresss type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 3 : 4;
}
$1 != "status" {
	a_stat = $1 == "G" ? "G, new" : $1
	printf("%s\t%s\t%s\t%s\n", a_stat, $f_addr, $5, $6)
}' $FILE	|\
sort -t $'\t' -u -k 2,2	|\
while read line ; do
	ins_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf("INSERT INTO addresses (a_stat, address, a_type, qry_address) VALUES ")
		printf("(")
		printf("%s", esc_string($1))
		printf(", %s", esc_string($2))
		printf(", %s", esc_string($4))
		printf(", %s", esc_string($3))
		printf(");\n")
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
        }')"
	sql_msg="$(echo -e "$ins_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ ! -z "$sql_msg" ] ; then
		addr="$(echo "$line" | awk -F'\t' '{ print $2 }')"
		err="$(echo "$sql_msg"	|\
			tail -1	|\
			awk -F: '{
				work = $(NF-1) ; sub(/^ */, "", work); printf("%s", work)
				work = $NF ; sub(/^ */, "", work); printf(": %s\n", work)
			}')"
		LOG ERROR "$err: $addr"
	fi
done
