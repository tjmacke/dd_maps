#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] data-dir"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

TMP_RFILE=/tmp/runs.$$
TMP_TS_FILE=/tmp/top_srcs.$$

DIR=

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
		DIR=$1
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

if [ -z "$DIR" ] ; then
	LOG ERROR "missing data-dir argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -d $DIR ] ; then
	LOG ERROR "data-dir $DIR does not exist or is not a directory"
	exit 1
fi

n_rfiles=$(ls $DIR/r*.tsv 2> /dev/null | wc -l)
if [ $n_rfiles -eq 0 ] ; then
	LOG ERROR "data-dir $DIR has no runs-files"
	exit 1
fi

echo -e "date\tp10\tp20\tp30\tp40\tp50" > $TMP_TS_FILE
for f in $DIR/r*.tsv ; do
	cat $f >> $TMP_RFILE
	$DM_SCRIPTS/count_addrs.sh -at src $TMP_RFILE	|\
	awk -F'\t' 'BEGIN {
		nf = split("'"$f"'", ary, ".")
		date = sprintf("%s-%s-%s", substr(ary[nf-1], 1, 4), substr(ary[nf-1], 5, 2), substr(ary[nf-1], 7, 2))
		p10 = p20 = p30 = p40 = p50 = 0
	}
	NR > 1 {
		if($4 >= 50){
			p50 = $1
			exit 0
		}else if($4 >= 40){
			if(p40 == 0)
				p40 = $1
		}else if($4 > 30){
			if(p30 == 0)
				p30 = $1
		}else if($4 >= 20){
			if(p20 == 0)
				p20 = $1
		}else if($4 >= 10){
			if(p10 == 0)
				p10 = $1
		}
	}
	END {
		printf("%s\t%d\t%d\t%d\t%d\t%d\n", date, p10, p20, p30, p40, p50)
	}'
done >> $TMP_TS_FILE

# Why? Well Rscript is in /usr/bin/ on Linux, but /usr/local/bin on Mac OS.  So
# this works as long as Rscript is install and in your path
Rscript $DM_LIB/plotSrcDiversityMain.R $TMP_TS_FILE

rm -rf $TMP_RFILE $TMP_TS_FILE
