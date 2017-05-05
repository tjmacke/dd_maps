#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -geo geocoder ] -at { src | dst } [ addr-geo-file ]"

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
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

GEO=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 1
		;;
	-geo)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-geo requires geocoder argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		GEO=$1
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
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$FILE" ] ; then
	if [ -z "$GEO" ] ; then
		LOG ERROR "-geo geocoder must be specified when reading from stdin"
		exit 1
	fi
else
	f_GEO="$(echo $FILE | awk -F. '{ print $3 }')"
fi

if [ -z "$GEO" ] ; then
	GEO=$f_GEO
elif [ "$GEO" != "$f_GEO" ] ; then
	LOG ERROR "specified geo, $GEO, does not match file geo, $f_GEO"
	exit 1
fi

cat $FILE	|\
while read line ; do
	upd_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		geo = "'"$GEO"'"
		atype = "'"$ATYPE"'"
		f_addr = atype == "src" ? 2 : 3
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		# Status is geo.ok.$GEO, where $GEO is the name of the geocoder that was used to resolve the address.
		printf("UPDATE addresses SET a_stat = %s, as_reason = %s, lng = %s, lat = %s, rply_address = %s WHERE address = %s ;\n", 
			esc_string("G"), esc_string(sprintf("geo.ok.%s", geo)), $4, $5, esc_string($6), esc_string($f_addr))
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	sql_msg="$(echo -e "$upd_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ ! -z "$sql_msg" ] ; then
		addr="$(echo "$line" | awk -F'\t' '{ print $("'"$ATYPE"'" == "src" ? 2 : 3) }')"
		err="$(echo "$sql_msg"	|\
			tail -1		|\
			awk -F: '{
				work = $(NF-1) ; sub(/^ */, "", work) ; printf("%s", work)
				work = $NF ; sub(/^ */, "", work) ; printf(": %s", work)
			}')"
		LOG ERROR "$err: $addr"
	fi
done
