#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] pay-summary-file"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_LIB=$DM_HOME/lib

FILE=

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
		FILE=$1
		shift
		break
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$FILE" ] ; then
	LOG ERROR "miss pay-summary-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

# Why? Well Rscript is in /usr/bin on Linux, but /usr/local/bin on Mac OS/X.  So
# this works as long as Rscript is installed and is in your path
Rscript $DM_LIB/plotPayRatesMain.R $FILE
