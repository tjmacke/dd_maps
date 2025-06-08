#! /bin/bash
#
function LOG {
	LEV=$1
	shift
	echo $(date '+%Y%m%d %H%M%S') T000000 $LEV ${FUNCNAME[1]}:${BASH_SOURCE[1]}:${BASH_LINENO[0]}: $* 1>&2
}
