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
	n_lines++
	lines[n_lines] = $0
}
END {
	if(n_lines == 0){
		printf("ERROR: config file contains only comments and/or blank lines\n") > "/dev/stderr"
		err = 1
		exit err
	}

	n_ptab = 0
	for(i = 1; i <= n_lines; i++){
		eq = index(lines[i], "=")
		if(eq == 0){
			printf("ERROR: line %7d: not key = value\n") > "/dev/stderr"
			err = 1
			exit err
		}
		keys[i] = trim(substr(lines[i], 1, eq - 1))
		values[i] = trim(substr(lines[i], eq + 1))
		dot = index(keys[i], ".")
		if(dot != 0){
			pfx = substr(keys[i], 1, dot - 1)
		
			if(!(pfx in ptab)){
				n_ptab++
				ptab[pfx] = 1
			}
			prefix[i] = pfx
			keys[i] = substr(keys[i], dot + 1)
		}else
			prefix[i] = ""
	}

	first = 1
	printf("{\n")
	for(i = 1; i <= n_lines; i++){
		if(prefix[i] == ""){
			if(first)
				first = 0
			else
				printf(",\n")
			printf("\"%s\": [", keys[i])
			printf("%s", mk_json_value(values[i]))
			printf("]")
		}
	}
	for(p in ptab){
		if(first)
			first = 0
		else
			printf(",\n")
		printf("\"%s\" : {\n", p)
		first_p = 1
		for(i = 1; i <= n_lines; i++){
			if(prefix[i] == p){
				if(first_p)
					first_p = 0
				else
					printf(",\n")
				printf("\"%s\": [", keys[i])
				printf("%s", mk_json_value(values[i]))
				printf("]")
			}
		}
		printf("\n}")
	}
	printf("\n}\n")

	exit 0
}
function trim(str,   work) {
	work = str
	sub(/^[ \t]*/, "", work)
	sub(/[ \t]*$/, "", work)
	return work
}
function mk_json_value(str,   nf, ary, f, v) {
	
	jval = ""
	nf = split(str, ary, "|")
	for(f = 1; f <= nf; f++){
		v = trim(ary[f])
		if(index(v, ",") != 0)
			jval = jval sprintf("[%s]", v)
		else if(v ~ /[A-Za-z]/)
			jval = jval sprintf("\"%s\"", v)
		else
			jval = jval sprintf("%s", v)
		jval = jval sprintf("%s", f < nf ? "," : "")
	}
	return jval
}' $FILE
