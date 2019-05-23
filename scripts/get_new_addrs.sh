#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -at { src | dst } [ -app { any*|gh|dd|pm|ue } ] [ runs-file ]"

ATYPE=
APP=any
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
			LOG ERROR "-at requries address-type argument"
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
	LOG ERROR "unknown address type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ "$APP" != "any" ] && [ "$APP" != "gh" ] && [ "$APP" != "dd" ] && [ "$APP" != "pm" ] && [ "$APP" != "ue" ] ; then
	LOG ERROR "unknown app $APP, must one of gh, dd, pm, ue or any"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 6 : 7
	app = "'"$APP"'"
	pr_hdr = 1
}
{
	if($5 == "Job"){
		if(!($1 in dates))
			n_dates++
		dates[$1]++
		if(!($f_addr in addrs))
			n_addrs++
		addrs[$f_addr]++
	}else if($5 == "END"){
		if(pr_hdr){
			pr_hdr = 0
			at_str = atype == "src" ? "Sources" : "Dests"
			printf("date\tnDashes\tn%s\tnNew%s\n", at_str, at_str)
		}
		printf("%s\t%d\t%d\t%d\n", $1, n_dates, n_addrs, n_addrs - l_na)
		l_na = n_addrs
	}
}' $FILE
