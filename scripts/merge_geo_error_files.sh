#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] err-file-1 [ err-file-2 ]"

FILE_1=
FILE_2=

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
		if [ -z "$FILE_1" ] ; then
			FILE_1=$1
			shift
		else
			FILE_2=$1
			shift
			break
		fi
	esac
done

if [ $# -ne 0 ] ; then
	LOG ERROR "extra arguments $*"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$FILE_1" ] ; then
	LOG ERROR "missing err-file-1 argument"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' '{
	n_lines++
	lines[n_lines] = $0
	if(FILENAME != l_FILENAME){
		fnum++
		l_first[fnum] = n_lines;
		l_count[fnum] = 0
		nf = split(FILENAME, ary, "/")
		nf2 = split(ary[nf], ary2, ".")
		geocoder[fnum] = ary2[1]
	}
	l_count[fnum]++
	l_FILENAME = FILENAME
}
END {
	for(i = 0; i < l_count[1]; i++){
		nf = split(lines[l_first[1]+i], ary, "\t")
		if(ary[1] == "ERROR"){
			addr = ary[4]
			a_first[addr] = l_first[1]+i
			a_count[addr] = 0
		}
		a_count[addr]++
	}
	in_rec = 0
	# TODO: deal with 1 file?
	for(i = 0; i < l_count[fnum]; i++){
		nf = split(lines[l_first[fnum]+i], ary, "\t")
		if(ary[1] == "ERROR"){
			in_rec = 1
			addr = ary[4]
			printf("%s\n", lines[l_first[fnum]+i])
			printf("\taddr      = %s\n", addr)
			for(j = 1; j < a_count[addr] - 1; j++){
				nf2 = split(lines[a_first[addr]+j], ary2, "\t")
				if(ary2[2] ~ /^emsg /)
					continue
				else if(ary2[2] ~ /^query /){
					nf3 = split(ary2[2], ary3, "=")
					for(k = 1; k <= nf3; k++){
						sub(/^ */, "", ary3[k])
						sub(/ *$/, "", ary3[k])
					}
					printf("\t%s     = %s\n", ary3[1], ary3[2])
				}else
					printf("\t%s.%s\n", geocoder[1], ary2[2])
			}
		}else if(ary[1] == "}"){
			in_rec = 0
			printf("%s\n", lines[l_first[fnum]+i])
		}else if(in_rec){
			if(ary[2] ~ /^query / || ary[2] ~ /^emsg/)
				continue
			printf("\t%s.%s\n", geocoder[fnum], ary[2])
		}
	}
}' $FILE_1 $FILE_2
