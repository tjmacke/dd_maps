#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -dh doordash-home ] -at { src | dst } [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	READ_ADDRESSES="$DM_LIB/read_addresses.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	READ_ADDRESSES="\"$DM_LIB/read_addresses.awk\""
else
	LOG ERROR "unsupported awk version: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

DD_HOME=
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-dh)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-dh requires doordash-home argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DD_HOME=$1
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

if [ -z "$DD_HOME" ] ; then
	LOG ERROR "DD_HOME is not defined"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

$AWK -F'\t' '
@include '"$READ_ADDRESSES"'
BEGIN {
	atype = "'"$ATYPE"'"
	if(atype == "src"){
		afield = 6
		afile = "'"$DD_HOME"'/maps/src.addrs"
	}else{
		afield = 7
		afile = "'"$DD_HOME"'/maps/dst.addrs"
	}
	# read the addresses
	n_a2idx = read_addresses(afile, a2idx, acnt, along, alat)
	if(n_a2idx == 0){
		printf("ERROR: no addresses in %s\n", afile) > "/dev/stderr"
		exit 1
	}
	printf("INFO: %s: %d %s addresses\n", afile, n_a2idx, atype) > "/dev/stderr"
}
$5 == "Job" {
	if($2 == "."){
		printf("ERROR: no start time for %s\n", $afield) > "/dev/stderr"
		next
	}else
		t_start = 60*substr($2, 1, 2) + substr($2, 4, 2)
	if($3 == "."){
		printf("ERROR: no end time for %s\n", $afield) > "/dev/stderr"
		next
	}else
		t_end = 60*substr($3, 1, 2) + substr($3, 4, 2)
	if(!($afield in a2idx)){
		printf("ERROR: no %s address for \"%s\"\n", atype, $afield) > "/dev/stderr"
		next
	}
	# compute elapsed time
	tr_time[$afield] += t_end - t_start
	tr_cnt[$afield]++
}
END {
	if(err)
		exit err
	for(addr in tr_time){
		idx = a2idx[addr]
		printf("%d\t%.1f\t%s\t%s\t%s\n", tr_cnt[addr], tr_time[addr]/tr_cnt[addr], addr, along[idx], alat[idx])
	}
}' $FILE
