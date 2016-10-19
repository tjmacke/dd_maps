#! /bin/bash
#
. ~/etc/funcs.sh

FILE=$1

awk -F'\t' '{
	printf("%s\t%s\t%s\n", $2, $4, $5)
}' $FILE	|\
sort		|\
uniq -c		|\
sed -e 's/^  *//'	|\
sed -e 's/ /	/'	|\
sort -t $'\t' -k 3g,3 -k 4g,4	|\
awk -F'\t' 'BEGIN {
	l_key[1] = ""
	l_key[2] = ""
}
{
	key[1] = $3
	key[2] = $4
	if(!key_equal(key, l_key)){
		if(!key_isempty(l_key)){
			if(n_lines > 1){
				for(i = 1; i <= n_lines; i++)
					printf("%s\n", lines[i])
				printf("\n")
			}
			delete lines
			n_lines = 0
		}
	}
	n_lines++
	lines[n_lines] = $0
	l_key[1] = key[1]
	l_key[2] = key[2]
}
END {
	if(!key_isempty(l_key)){
		if(n_lines > 1){
			for(i = 1; i <= n_lines; i++)
				printf("%s\n", lines[i])
		}
		delete lines
		n_lines = 0
	}
}
function key_equal(k1, k2) {
	return k1[1] == k2[1] && k1[2] == k2[2]
}
function key_isempty(k1) {
	return k1[1] == "" || k1[2] == ""
}'
