#! /bin/bash
#

# Very simple logging function, using the same format as log.h/log.c
# Each message is preceded by 5 fields
# 1  The date as YYYYMMDD
# 2  The time as HHMMSS
# 3  The "thread id", which is defined as T000000 as I have no idea how to write multi-threaded bash scripts
#    However, I do know how to write multi-threaded C/C++ programs where it is useful
# 4  The logging level, which is just a string w/o spaces or special chars.  For log.h I used ERROR/WARN/INFO/DEBUG
# 5  The location of the log message as funcName:fileName:lineNumber
# 6  Your message

function LOG {
	LEV=$1
	shift
	echo $(date '+%Y%m%d %H%M%S') T000000: $LEV: ${FUNCNAME[1]}:${BASH_SOURCE[1]}:${BASH_LINENO[0]}: "$*" 1>&2
}

U_MSG="usage: $0 [ -help ] [ gallery-json-file ]"

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
		;;
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk '{
	if($1 == "\"geojson\":"){
		in_geojson = 1
		lev = 1
		printf("{\n")
	}else if(in_geojson){
		printf("%s\n", $0)
		if($0 ~ "{$"){
			lev++
		}else if($0 ~ /^ *}$/ || $0 ~ /^ *},/ || $0 ~ /^ *} /){
			lev--
			if(lev == 0)
				exit 0
		}
	}
}' $FILE

exit 0
