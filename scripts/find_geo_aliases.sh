#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

echo -e ".mode tabs\nSELECT address, lng, lat FROM addresses WHERE a_stat = 'G' AND as_reason = 'geo' ORDER BY lng, lat ;"	|\
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
				for(i = 1; i <= n_lines; i++)
					printf("\t%s\n", lines[i])
				printf("}\n")
			}
			delete lines
			n_lines = 0
		}
	}
	n_lines++
	lines[n_lines] = $1
	l_key[1] = key[1]
	l_key[2] = key[2]
}
END {
	if(!key_isempty(l_key)){
		if(n_lines > 1){
			printf("geo(%s, %s) = %d {\n", l_key[1], l_key[2], n_lines)
			for(i = 1; i <= n_lines; i++)
				printf("\t%s\n", lines[i])
			printf("}\n")
		}
		delete lines
		n_lines = 0
	}
}
function key_equal(k1, k2) {
	return k1[1] == k2[1] && k1[2] == k2[2]
}
function key_isempty(k1) {
	return k1[1] == "" || k1[2] == ""
}'
