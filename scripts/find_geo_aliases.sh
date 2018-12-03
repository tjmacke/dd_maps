#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] db-file"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
# set these from the cmd-line
#DM_ADDRS=$DM_HOME/addrs
#DM_DB=$DM_ADDRS/dd_maps.db

#if [ ! -s $DM_DB ] ; then
#	LOG ERROR "database $DM_DB either does not exist or has zero size"
#	exit 1
#fi

DB_DB=

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
		DM_DB=$1
		shift
		break
		;;
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
elif [ -z "$DM_DB" ] ; then
	LOG ERROR "missing db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

echo -e ".mode tabs\nPRAGMA foreign_keys = on ;\nSELECT address, lng, lat FROM addresses WHERE a_stat = 'G' AND as_reason LIKE 'geo.ok.%' ORDER BY lng, lat ;"	|\
sqlite3 $DM_DB	|\
awk -F'\t' 'BEGIN {
	l_key[1] = ""
	l_key[2] = ""
}
{
	key[1] = $2
	key[2] = $3
	if(!key_equal(key, l_key)){
		if(!key_isempty(l_key)){
			if(n_lines > 1){
				printf("geo(%s, %s) = %d {\n", l_key[1], l_key[2], n_lines)
				asorti(lines, lines_idx)
				for(i = 1; i <= n_lines; i++)
					printf("\t%s\n", lines_idx[i])
				printf("}\n")
			}
			delete lines
			delete line_idx
			n_lines = 0
		}
	}
	n_lines++
	lines[$1] = n_lines
	l_key[1] = key[1]
	l_key[2] = key[2]
}
END {
	if(!key_isempty(l_key)){
		if(n_lines > 1){
			printf("geo(%s, %s) = %d {\n", l_key[1], l_key[2], n_lines)
			asorti(lines, lines_idx)
			for(i = 1; i <= n_lines; i++)
				printf("\t%s\n", lines_idx[i])
			printf("}\n")
		}
		delete lines
		delete lines_idx
		n_lines = 0
	}
}
function key_equal(k1, k2) {
	return k1[1] == k2[1] && k1[2] == k2[2]
}
function key_isempty(k1) {
	return k1[1] == "" || k1[2] == ""
}'
