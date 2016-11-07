#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ config-file ]"

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
	if(substr($0, 1, 1) == "#")
		next
	if($0 ~ /^[ \t]*$/)
		next
	n_clines++
	clines[n_clines] = $0
}
END {
	if(n_clines == 0){
		printf("ERROR: config file contains only comments an blank lines\n") > "/dev/stderr"
		err = 1
		exit err
	}

	printf("{\n")
	for(i = 1; i <= n_clines; i++){
		nf = split(clines[i], ary, "=")
		key = trim(ary[1])
		value = trim(ary[2])
		nf2 = split(value, ary2, "|")
		printf("  \"%s\": [", key)
		for(j = 1; j <= nf2; j++){
			v = trim(ary2[j])
			if(index(v, ",") != 0)
				printf("[%s]", v)
			else if(v ~ /[A-Za-z]/)
				printf("\"%s\"", v)
			else
				printf("%s", v)
			printf("%s", j < nf2 ? "," : "")
		}
		printf("]%s\n", i < n_clines ? "," : "")
	}
	printf("}\n")

	exit 0
}
function trim(str,   work) {
	work = str
	sub(/^[ \t]*/, "", work)
	sub(/[ \t]*$/, "", work)
	return work
}' $FILE
