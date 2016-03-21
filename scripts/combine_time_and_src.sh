#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -dh doordash-home ] [ runs-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK=igawk
	READ_ADDRESSES="$DM_LIB/read_addresses.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	READ_ADDRESSES="\"$DM_LIB/read_addresses.awk\""
else
	LOG ERROR "bad AWK_VERSION: \"$AWK_VERSION\": must be 3 or 4"
	exit 1
fi

DD_HOME=
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

awk -F'\t' '
@include '"$READ_ADDRESSES"'
BEGIN {
	# read the src addresses
	safile = "'"$DD_HOME"'/maps/src.addrs"
	n_sa2idx = read_addresses(safile, sa2idx, sacnt, salong, salat)
	if(n_sa2idx == 0){
		printf("ERROR: no addresses in %s\n", safile) > "/dev/stderr"
		exit 1
	}
	printf("INFO: %s: %d addresses\n", safile, n_sa2idx) > "/dev/stderr"
}
$5 == "Job" {
	if($2 == "."){
		printf("ERROR: no start time for %s\n", $6) > "/dev/stderr"
		next
	}else
		t_start = 60*substr($2, 1, 2) + substr($2, 4, 2)
	if($3 == "."){
		printf("ERROR: no end time for %s\n", $6) > "/dev/stderr"
		next
	}else
		t_end = 60*substr($3, 1, 2) + substr($3, 4, 2)
	if(!($6 in sa2idx)){
		printf("ERROR: no address for %s\n", $6) > "/dev/stderr"
		next
	}
	# compute elapsed time
	tr_time[$6] += t_end - t_start
	tr_cnt[$6]++
}
END {
	if(err)
		exit err
	for(addr in tr_time){
		idx = sa2idx[addr]
		printf("%d\t%.1f\t%s\t%s\t%s\n", tr_cnt[addr], tr_time[addr]/tr_cnt[addr], addr, salong[idx], salat[idx])
	}
}' $FILE
