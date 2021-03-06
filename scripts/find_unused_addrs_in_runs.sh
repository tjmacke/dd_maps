#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -db db-file [ runs-file ]"

TMP_AFILE=/tmp/addrs.$$

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
		LOG ERROR "unkonwn option $1"
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
	LOG ERROR "extra arguments"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing -db db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

sqlite3 $DM_DB > $TMP_AFILE <<_EOF_
.mode tab
select address from addresses ;
_EOF_

awk -F'\t' 'BEGIN {
	afile = "'"$TMP_AFILE"'"
	for(n_atab = 0; (getline < afile) > 0; ){
		n_atab++
		atab[$0] = 0
	}
	close(afile)
}
$5 == "Job" {
	if($6 in atab)
		atab[$6] = 1
	if($7 in atab)
		atab[$7] = 1
}
END {
	for(a in atab){
		if(atab[a] == 0)
			printf("%s\n", a)
	}
}' $FILE

rm -f $TMP_AFILE
