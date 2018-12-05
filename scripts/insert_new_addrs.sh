#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -db db-file [ -no_insert ] -at { src | dst } [ parsed-address-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

TMP_AFILE=/tmp/addrs.$$

DM_DB=
NO_INSERT=
ATYPE=
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
	-no_insert)
		NO_INSERT="yes"
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

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing -db db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" == "src" ] ; then
	f_addr=3
elif [ "$ATYPE" == "dst" ] ; then
	f_addr=4
else
	LOG ERROR "unknown addresss type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

sqlite3 $DM_DB > $TMP_AFILE <<_EOF_
.mode tabs
PRAGMA foreign_keys = on ;
SELECT address, date_first_use, date_last_use FROM addresses ;
_EOF_

grep -v '^status' $FILE	|\
sort -t $'\t' -k $f_addr,$f_addr -k 2,2 $FILE	|\
awk -F'\t' '
# INPUT:	status	date	src	dst	qAddr	aName 	# qAddr, aName is either src/dst
# OUTPUT:	status	f_date	l_date	addr	qAddr	aName	# unused src or dst dropped
BEGIN {
	f_addr = "'"$f_addr"'"
}
{
	if($f_addr != lf_addr){
		if(lf_addr != ""){
			printf("%s\t%s\t%s\t%s\t%s\t%s\n", l_1, f_date, l_date, lf_addr, l_5, l_6)
			f_date = ""
		}
	}
	l_1 = $1
	if(f_date == "")
		f_date = $2
	l_date = $2
	lf_addr = $f_addr
	l_5 = $5
	l_6 = $6
}
END {
	if(lf_addr != ""){
		printf("%s\t%s\t%s\t%s\t%s\t%s\n", l_1, f_date, l_date, lf_addr, l_5, l_6)
		f_date = ""
	}
}'	|\
awk -F'\t' '
# INPUT:	status	f_date	l_date	addr	qAddr	aName
# OUTPUT:	new stmts:	I	a_stat, as_reason f_date	l_date	addr	qAddr	aName
#		new l_date:	U_l	addr	l_date
#		new f_date	U_f	addr	f_date
BEGIN {
	afile = "'"$TMP_AFILE"'"
	for(n_atab = 0; (getline < afile) > 0; ){
		n_atab++
		atab[$1] = 1
		a_first[$1] = $2
		a_last[$1] = $3
	}
	close(afile)
}
{
	if(!($4 in atab)){
		a_stat = $1 == "G" ? "G, new" : $1
		printf("I\t%s\t%s\t%s\t%s\t%s\t%s\n", a_stat, $2, $3, $4, $5, $6)
	}else if($3 > a_last[$4])
		printf("U_l\t%s\t%s\n", $4, $3)
	else if($2 < a_first[$4])
		printf("U_f\t%s\t%s\n", $4, $3)
}'	|\
while read line ; do
	ins_stmt="$(echo "$line" |\
	awk -F'\t' 'BEGIN {
		apos = sprintf("%c", 39)
	}
	{
		n_ary = split($2, ary, ",")
		for(i = 1; i <= n_ary; i++){
			sub(/^ */, "", ary[i])
			sub(/ *$/, "", ary[i])
		} 
		printf(".log stderr\\n")
		printf("PRAGMA foreign_keys = on ;\\n")
		if($1 == "I"){
			printf("INSERT INTO addresses (a_stat, as_reason, address, a_type, qry_address, date_first_use, date_last_use) VALUES ")
			printf("(")
			printf("%s", esc_string(ary[1]))
			printf(", %s", esc_string(ary[2]))
			printf(", %s", esc_string($5))
			printf(", %s", esc_string($7))
			printf(", %s", esc_string($6))
			printf(", %s", esc_string($3))
			printf(", %s", esc_string($4))
			printf(");\n")
		}else if($1 == "U_l"){
			printf("UPDATE addresses SET date_last_use = %s where address = %s;\n", esc_string($3), esc_string($2))
		}else{
			printf("UPDATE addresses SET date_first_use = %s where address = %s;\n", esc_string($3), esc_string($2))
		}
	}
	function esc_string(str,   work) {
		work = str
		gsub(apos, apos apos, work)
		return apos work apos
        }')"
	if [ "$NO_INSERT" != "yes" ] ; then
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
	else
		echo "$ins_stmt"
	fi
done

rm -f $TMP_AFILE
