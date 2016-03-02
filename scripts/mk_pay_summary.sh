#! /bin/bash
#
. ~/etc/funcs.sh

FILE=$1

awk -F'\t'	'BEGIN {
	pr_hdr = 1
}
{
	if($2 == "pay"){
		# format: date type deliveries hours amount
		if($1 != l_1){
			if(l_1 != ""){
				if(pr_hdr){
					pr_hdr = 0
					printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "date", "deliveries", "hours", "amount", "hrate", "drate", "dph")
				}
				printf("%s\t%d\t%d\t%.2f\t%.2f\t%.2f\t%.2f\n", l_1, l_3, l_4, l_5, l_5/l_4, l_5/l_3, 1.*l_3/l_4)
			}
		}
		l_1 = $1
		l_3 = $3
		l_4 = $4
		l_5 = $5
	}
}
END {
	if(l_1 != ""){
		if(pr_hdr){
			pr_hdr = 0
			printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "date", "deliveries", "hours", "amount", "hrate", "drate", "dph")
		}
		printf("%s\t%d\t%d\t%.2f\t%.2f\t%.2f\t%.2f\n", l_1, l_3, l_4, l_5, l_5/l_4, l_5/l_3, 1.*l_3/l_4)
	}
}' $FILE
