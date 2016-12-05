#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ pay-file_1 ... ]"

FLIST=

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
		if [ -z "$FLIST" ] ; then
			FLIST=$1
		else
			FLIST="$FLIST $1"
		fi
		shift
		;;
	esac
done

cat $FLIST	|\
awk -F'\t' '{
	if(NR == 1){
		print $0
		next
	}
	if($2 != "pay")
		next
	if($1 != l_1){
		if(l_1 != ""){
			print pay[l_1]
		}
	}
	pay[$1] = $0
	l_1 = $1
}
END {
	if(l_1 != ""){
		print pay[l_1]
	}
}'
