#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -at { src | dst } [ -app { ALL*|gh|dd|cav|pm|ue } ] source-file"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

APP=ALL
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
	-app)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-app requires app-name argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		APP=$1
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
	LOG ERROR "unknown address type $atype, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ "$APP" != "ALL" ] && [ "$APP" != "gh" ] && [ "$APP" != "dd" ] && [ "$APP" != "cav" ] && [ "$APP" != "pm" ] && [ "$APP" != "ue" ] ; then
	LOG ERROR "unknown app $APP, must one of gh, dd, cav, pm, ue or ALL"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$FILE" ] ; then
	LOG ERROR "miss source-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

# Why? Well Rscript is in /usr/bin on Linux, but /usr/local/bin on Mac OS/X.  So
# this works as long as Rscript is installed and is in your path
Rscript $DM_LIB/plotAddrInfoMain.R -at $ATYPE -app $APP $FILE
