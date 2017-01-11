#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -a addrs-file [ runs-file ]"

AFILE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-a)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-a requires fixed-addrs-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		AFILE=$1
		shift
		;;
	-*)
		LOG ERROR "unkonwn option $1"
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
	LOG ERROR "extra arguments"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$AFILE" ] ; then
	LOG ERROR "missing -a fixed-addrs-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' 'BEGIN {
	afile = "'"$AFILE"'"
	for(n_atab = 0; (getline < afile) > 0; ){
		n_atab++
		atab[$0] = 0
	}
	close(afile)
}
$5 == "Job" {
	if($6 in atab)
		atab[$6] = 1
	if($7 in atab)
		atab[$7] = 1
}
END {
	for(a in atab){
		if(atab[a] == 0)
			printf("%s\n", a)
	}
}' $FILE
