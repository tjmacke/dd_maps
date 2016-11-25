#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] [ -dh doordash-home ] error-file"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined."
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

EFILE=

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
		EFILE=$1
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

if [ -z "$EFILE" ] ; then
	LOG ERROR "missing error-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

MONTH="$(echo $EFILE | awk -F. '{ print $3 }')"
RUNS=$DD_HOME/data/runs.$MONTH.tsv

# keep opencagedata happy
n_errs=$(grep '^ERROR' $EFILE | wc -l)
if [ $n_errs -ge 40 ] ; then
	t_sleep=5
elif [ $n_errs -ge 20 ] ; then
	t_sleep=3
elif [ $n_errs -ge 10 ] ; then
	t_sleep=2
else
	t_sleep=0
fi
if [ $t_sleep -gt 0 ] ; then
	LOG INFO "$EFILE: $n_errs errors, will sleep $t_sleep seconds between queries to keep opencagedata.com happy"
fi

cat $EFILE	|\
while read line ; do
	qry="$(echo "$line"	|\
		awk '{
			if($0 ~ /^ERROR/){
				nf = split($0, ary, ":")
				for(i = 1; i <= nf; i++){
					sub(/^  */, "", ary[i])
					sub(/  *$/, "", ary[i])
				}
				print ary[nf-1] == "not found" ? ary[nf-2] : ""
			}else
				print ""
		}'
	)"
	if [ -z "$qry" ] ; then
		continue
	fi
	atype="$(echo "$line" | awk -F: '{ print $3 }')"
	$DM_SCRIPTS/chk_1_address.sh -dh $DD_HOME -at $atype -m $MONTH "$qry"
	echo ""
	if [ $t_sleep -gt 0 ] ; then
		sleep $t_sleep
	fi
done
