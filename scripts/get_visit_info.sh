#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } [ -w where ] [ -u { weeks* | days } ] [ -meta meta-file ] db"

ATYPE=
WHERE=
UNIT=
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
	-w)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-w requires where clause argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		WHERE="$1"
		shift
		;;
	-u)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-u require unit argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		UNIT=$1
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

if [ ! -z "$UNIT" ] ; then
	if [ "$UNIT" == "weeks" ] ; then
		U_DIV=7
	elif [ "$UNIT" == "days" ] ; then
		U_DIV=1
	else
		LOG ERROR "unknown unit \"$UNIT\", must be weeks, or days"
		echo "$U_MSG" 1>&2
		exit 1
	fi
else
	UNIT="weeks"
	U_DIV=7
fi

if [ -z "$DB" ] ; then
	LOG ERROR "missing db argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DB ] ; then
	LOG ERROR "database $DB either does not exist or has zero size"
	exit 1
fi

if [ ! -z "$WHERE" ] ; then
	WHERE="WHERE $WHERE"
fi

sqlite3 $DB <<_EOF_
.headers on
.mode tabs
PRAGMA foreign_keys = ON ;
SELECT	MAX(strftime('%Y-%m-%d', time_start)) AS last,
	$ATYPE.address AS address,
	COUNT($ATYPE.address) AS visits,
	$ATYPE.lng AS lng,
	$ATYPE.lat AS lat,
	printf('%.5f', (julianday((SELECT strftime('%Y-%m-%d', MAX(time_start)) FROM jobs)) - julianday(MAX(strftime('%Y-%m-%d', time_start))))/$U_DIV) AS $UNIT,
	printf('%s:<br/>visits=%s, last=%s', address, COUNT($ATYPE.address), MAX(strftime('%Y-%m-%d', time_start))) AS title
FROM jobs
INNER JOIN addresses $ATYPE ON $ATYPE.address_id = jobs.${ATYPE}_addr_id
-- WHERE date(time_start) >= '2021-03-22'
$WHERE
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
