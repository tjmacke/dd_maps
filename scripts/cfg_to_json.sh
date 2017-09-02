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
	main_scale = ""
	aux_scale = ""
	n_keys = 0
	for(i = 1; i <= n_lines; i++){
		eq = index(lines[i], "=")
		if(eq == 0){
			printf("ERROR: line %7d: not key = value\n") > "/dev/stderr"
			err = 1
			exit err
		}
		key = trim(substr(lines[i], 1, eq - 1))
		value = trim(substr(lines[i], eq + 1))
		if(key == "main"){
			main_scale = value
			continue
		}else if(key == "aux"){
			aux_scale = value
			continue
		}
		n_keys++
		keys[n_keys] = key
		values[n_keys] = value
		dot = index(keys[n_keys], ".")
		if(dot != 0){
			pfx = substr(keys[n_keys], 1, dot - 1)
		
			if(!(pfx in ptab)){
				n_ptab++
				ptab[pfx] = 1
			}
			prefix[n_keys] = pfx
			keys[n_keys] = substr(keys[n_keys], dot + 1)
		}else
			prefix[n_keys] = ""
	}
	# TODO: is this the right thing?
	# if(main_scale == "" && aux_scale == ""){
	#	printf("ERROR: END: neither the main or aux scale is set\n") > "/dev/stderr"
	#	err = 1
	#	exit err
	# }

	first = 1
	printf("{\n")
	for(i = 1; i <= n_keys; i++){
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
		if(p == main_scale)
			key = "main"
		else if(p == aux_scale)
			key = "aux"
		else
			key = p
		printf("\"%s\" : {\n", key)
		first_p = 1
		for(i = 1; i <= n_keys; i++){
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
