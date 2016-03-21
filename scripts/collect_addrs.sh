#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } [ addr-geo-file ]"

ATYPE=
FILE=

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
	LOG ERROR "unknown address-type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 2 : 3
}
{
	addr = $f_addr

	if(!(addr in a2idx)){
		n_a2idx++
		a2idx[addr] = n_a2idx
		acnt[n_a2idx] = 1
		lat[n_a2idx] = $5
		long[n_a2idx] = $4
	}else{
		idx = a2idx[addr]
		acnt[idx]++
	}
}
END {
	for(addr in a2idx){
		idx = a2idx[addr]
		printf("%d\t%s\t%s\t%s\n", acnt[idx], addr, long[idx], lat[idx])
	}
}' $FILE
