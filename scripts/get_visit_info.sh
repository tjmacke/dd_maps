#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } [ -meta meta-file ] db"

ATYPE=
MFILE=
DB=

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
	-meta)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-meta requires meta-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		MFILE=$1
		shift
		;;
	-*)
		LOG ERROR "unknown option $1"
		echo "$U_MSG" 1>&2
		exit 1
		;;
	*)
		DB=$1
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
	echo "$U_MSB" 1>&2
	exit 1
elif [ "$ATYPE" == "src" ] ; then
	AT_NAME=sources
elif [ "$ATYPE" == "dst" ] ; then
	AT_NAME=dests
else
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DB" ] ; then
	LOG ERROR "missing db argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DB ] ; then
	LOG ERROR "database $DB either does not exist or has zero size"
	exit 1
fi

sqlite3 $DB <<_EOF_
.headers on
.mode tabs
PRAGMA foreign_keys = ON ;
SELECT	printf('%.5f', (julianday((SELECT strftime('%Y-%m-%d', MAX(time_start)) FROM jobs)) - julianday(MAX(strftime('%Y-%m-%d', time_start))))/7) AS weeks,
	count($ATYPE.address) AS visits,
	max(strftime('%Y-%m-%d', time_start)) AS last,
	$ATYPE.address AS address,
	$ATYPE.lng AS lng,
	$ATYPE.lat AS lat
FROM jobs
INNER JOIN addresses $ATYPE ON $ATYPE.address_id = jobs.${ATYPE}_addr_id
GROUP BY $ATYPE.address ;
_EOF_

if [ ! -z "$MFILE" ] ; then
	sqlite3 $DB <<-_EOF_ > $MFILE
	PRAGMA foreign_keys = ON ;
	SELECT	printf('data_stats = "%d $AT_NAME, %d dashes, last = %s"',
		(SELECT COUNT(DISTINCT $ATYPE.address)
			FROM jobs
			INNER JOIN addresses $ATYPE ON $ATYPE.address_id = jobs.${ATYPE}_addr_id),
		(SELECT COUNT(dash_id)
			FROM dashes),
		(SELECT strftime('%Y-%m-%d', MAX(time_start))
			FROM dashes)) ;
	SELECT  printf('center = %.15f, %.15f', AVG(DISTINCT $ATYPE.lng), AVG(DISTINCT $ATYPE.lat))
		FROM jobs
		INNER JOIN addresses $ATYPE ON $ATYPE.address_id = jobs.${ATYPE}_addr_id ;
	_EOF_
fi
