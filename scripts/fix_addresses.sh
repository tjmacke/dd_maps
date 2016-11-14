#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] -af alias-file -at { src | dst } runs-file ... ]"

AFILE=
ATYPE=
RFILES=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_UMSG"
		exit 0
		;;
	-af)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-af requires alias-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		AFILE=$1
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
		if [ ! -z "$RFILES" ] ; then
			RFILES="$RFILES $1"
		else
			RFILES=$1
		fi
		shift
		;;
	esac
done

if [ -z "$RFILES" ] ; then
	LOG ERROR "No runs-files"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$AFILE" ] ; then
	LOG ERROR "missing -af alias-file argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

for rf in $RFILES ; do
	LOG INFO "check $rf for incorrect addresses"
	fix="$(
		awk -F '\t' 'BEGIN {
			atype = "'"$ATYPE"'"
			f_addr = atype == "src" ? 6 : 7
			afile = "'"$AFILE"'"
			for(n_atab = 0; (getline < afile) > 0; ){
				n_atab++
				atab[$1] = $2
			}
			close(afile)
		}
		$5 == "Job" {
			if($f_addr in atab){
				fix = "yes"
				exit
			}
		}
		END {
			printf("%s\n", fix)
			exit 0
		}' $rf
	)"
	if [ "$fix" == "yes" ] ; then
		LOG INFO "$rf has incorrect addresses, fixing"
		rf_bak=$rf.BAK
		cp $rf $rf_bak
		awk -F'\t' 'BEGIN {
			atype = "'"$ATYPE"'"
			f_addr = atype = "arc" ? 6 : 7
			afile = "'"$AFILE"'"
			for(n_atab = 0; (getline < afile) > 0; ){
				n_atab++
				atab[$1] = $2
			}
			close(afile)
		}
		{
			if($5 == "Job"){
				if($f_addr in atab){
					for(i = 1; i < f_addr; i++)
						printf("%s%s", i > 1 ? "\t" : "", $i)
					printf("\t%s", atab[$f_addr])
					for(i = f_addr + 1; i <= NF; i++)
						printf("\t%s", $i)
					printf("\n")
				}else
					printf("%s\n", $0)
			}else
				printf("%s\n", $0)
		}' $rf_bak > $rf
		LOG INFO "$rf incorrect addresses fixed"
	else
		LOG INFO "$rf has no incorrect addresses"
	fi
done
