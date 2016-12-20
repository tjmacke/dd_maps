#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] (no options or argumets)"

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
		LOG ERROR "extra arguments $*"
		echo "$U_MSG" 1>&2
		exit 1
		;;
	esac
done

echo -e ".mode tabs\nSELECT qry_address, address FROM addresses WHERE qry_address != '' ORDER BY qry_address, address ;"	|\
sqlite3 $DM_DB															|\
awk -F'\t' '{
	if($1 != l_1){
		if(l_1 != ""){
			if(n_addrs > 1){
				printf("qry = %s {\n", l_1)
				for(i = 1; i <= n_addrs; i++)
					printf("\t%s\n", addrs[i])
				printf("}\n")
			}
			delete addrs
			n_addrs = 0
		}
	}
	n_addrs++
	addrs[n_addrs] = $2
	l_1 = $1
}
END {
	if(l_1 != ""){
		if(n_addrs > 1){
			printf("qry = %s {\n", l_1)
			for(i = 1; i <= n_addrs; i++)
				printf("\t%s\n", addrs[i])
			printf("}\n")
		}
		delete addrs
		n_addrs = 0
	}
}'