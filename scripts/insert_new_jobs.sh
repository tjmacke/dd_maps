#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -db db-file [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
# set these from the cmd line
#DM_ADDRS=$DM_HOME/addrs
#DM_DB=$DM_ADDRS/dd_maps.db

#if [ ! -s $DM_DB ] ; then
#	LOG ERROR "database $DM_DB either does not exist or has zero size"
#	exit 1
#fi

# awk v3 does not support includes
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	DASH_UTILS="$DM_LIB/dash_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	DASH_UTILS="\"$DM_LIB/dash_utils.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

DM_DB=
FILE=

TMP_JFILE=/tmp/jobs.$$
TMP_FILE=/tmp/file.$$

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

# get the jobs
sqlite3 $DM_DB > $TMP_JFILE <<_EOF_
.mode tabs
PRAGMA foreign_keys = on ;
SELECT time_start, src.address, dst.address
FROM jobs
INNER JOIN addresses src ON src.address_id = jobs.src_addr_id
INNER JOIN addresses dst ON dst.address_id = jobs.dst_addr_id ;
_EOF_

# find new jobs
awk -F'\t' 'BEGIN {
	jfile = "'"$TMP_JFILE"'"
	for(n_jtab = 0; (getline < jfile) > 0; ){
		n_jtab++
		jtab[$0] = 1
	}
	close(jfile)
}
$5 == "Job" {
	job = sprintf("%s\t%s\t%s", $1 "T" $2, $6, $7)
	if(!(job in jtab))
		printf("%s\n", $0)
}' $FILE	|\
while read line ; do

#LOG DEBUG "line = $line"

	# get the src_addr_id
	src="$(echo "$line" | awk -F'\t' '{ print $6 }')"
	sel_stmt="$(echo "$src" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf(".mode tabs\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		printf("SELECT address_id FROM addresses WHERE address = %s ;\n", esc_string($1))
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	src_addr_id="$(echo -e "$sel_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ -z "$src_addr_id" ] ; then
		LOG ERROR "src address $src not in addresses table"
		continue
	fi

	# get the dst_addr_id
	dst="$(echo "$line" | awk -F'\t' '{ print $7 }')"
	sel_stmt="$(echo "$dst" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf(".mode tabs\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		printf("SELECT address_id FROM addresses WHERE address = %s ;\n", esc_string($1))
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"
	dst_addr_id="$(echo -e "$sel_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ -z "$src_addr_id" ] ; then
		LOG ERROR "src address $src not in addresses table"
		continue
	fi

	# get the dash id
	# dashes, at this point are always contained in 1 calendar day: [00:00, 23:59], which 
	# is why the query checks only the date part of the time_start
	date="$(echo "$line" | awk -F'\t' '{ print $1 }')"
	tstart="$(echo "$line" | awk -F'\t' '{ print $2 }')"
	sel_stmt="$(echo "$date" |\
	$AWK -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		printf(".log stderr\\n")
		printf(".mode tabs\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		printf("SELECT dash_id, time_start, time_end FROM dashes WHERE time_start LIKE %s%s%%%s;\n", apos, $1, apos)
	}')"
	dash_id="$(echo -e "$sel_stmt" | sqlite3 $DM_DB 2> /dev/null	|\
	awk -F'\t' '
	@include '"$DASH_UTILS"'
	BEGIN {
		tstart = "'"$tstart"'"
	}
	{
		dstart = substr($2, 12)
		dend = substr($3, 12)

		if(DU_job_in_dash(tstart, "", dstart, dend)){
			printf("%d\n", $1)
			exit 0
		}
	}')"
	if [ -z "$dash_id" ] ; then
		LOG ERROR "no dash data for job $line"
		continue
	fi

	ins_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
		dash_id = "'"$dash_id"'" + 0
		src_addr_id = "'"$src_addr_id"'" + 0
		dst_addr_id = "'"$dst_addr_id"'" + 0
	}
	{
		t_start = $1 "T" $2
		t_end = $1 "T" $3
		printf(".log stderr\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		printf("INSERT INTO jobs (dash_id, time_start, time_end, src_addr_id, dst_addr_id, amount, payment, notes")
		printf(") VALUES (")
		printf("%d", dash_id)
		printf(", %s", esc_string(t_start))
		printf(", %s", esc_string(t_end))
		printf(", %d", src_addr_id)
		printf(", %d", dst_addr_id)
		printf(", %s", $8)
		printf(", %s", esc_string($9))
		printf(", %s", esc_string($10 != "." ? $10 : ""))
		printf(");\n")
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
	}')"

	# Do the insert.
	sql_msg="$(echo -e "$ins_stmt" | sqlite3 $DM_DB 2>&1)"
	if [ ! -z "$sql_msg" ] ; then
		err="$(echo "$sql_msg"	|\
			tail -1		|\
			awk -F: '{
				work = $(NF-1) ; sub(/^ */, "", work) ; printf("%s", work)
				work = $NF ; sub(/^ */, "", work) ; printf(": %s", work)
			}')"
		LOG ERROR "$err: $line"
	fi
done

rm -f $TMP_JFILE $TMP_FILE
