#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ runs-file ]"

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

awk -F'\t' 'BEGIN {
	numFields["jobType"] = 10
	numFields["BEGIN"]   =  7
	numFields["END"]     =  5
	numFields["Job"]     = 10
	numFields["Expense"] =  7
	numFields["Reject"]  = 10
}
{
	if($5 == "jobType"){
		# Date    tStart  tEnd    Mileage jobType locStart        locEnd  Amount  Payment Notes
		delete fspecs
		n_fspecs = 10
		fspecs[ 1, "type"] = "str" ; fspecs[ 1, "value"] = "Date"
		fspecs[ 2, "type"] = "str" ; fspecs[ 2, "value"] = "tStart"
		fspecs[ 3, "type"] = "str" ; fspecs[ 3, "value"] = "tEnd"
		fspecs[ 4, "type"] = "str" ; fspecs[ 4, "value"] = "Mileage"
		fspecs[ 5, "type"] = "str" ; fspecs[ 5, "value"] = "jobType"
		fspecs[ 6, "type"] = "str" ; fspecs[ 6, "value"] = "locStart"
		fspecs[ 7, "type"] = "str" ; fspecs[ 7, "value"] = "locEnd"
		fspecs[ 8, "type"] = "str" ; fspecs[ 8, "value"] = "Amount"
		fspecs[ 9, "type"] = "str" ; fspecs[ 9, "value"] = "Payment"
		fspecs[10, "type"] = "str" ; fspecs[10, "value"] = "Notes"
		if(chk_fspecs($5, NF, n_fspecs, fspecs)){
			err = 1
			next
		}
	}else if($5 == "BEGIN"){
		# date	time	time	int	"BEGIN"	string	/^DriverApp=[0-9][0-9]*$/
		delete fspecs
		n_fspecs = 7
		fspecs[ 1, "type"] = "date"
		fspecs[ 2, "type"] = "time"
		fspecs[ 3, "type"] = "time"
		fspecs[ 4, "type"] = "int"
		fspecs[ 5, "type"] = "str"   ; fspecs[ 5, "value"] = "BEGIN"
		fspecs[ 6, "type"] = "str"
		fspecs[ 7, "type"] = "regex" ; fspecs[ 7, "value"] = "^DriverApp=[0-9][0-9]*$"
		if(chk_fspecs($5, NF, n_fspecs, fspecs)){
			err = 1
			next
		}
	}else if($5 == "END"){
		# date	"."	time	int	"END"
		delete fspecs
		n_fspecs = 5
		fspecs[ 1, "type"] = "date"
		fspecs[ 2, "type"] = "str"  ; fspece[ 2, "value"] = "."
		fspecs[ 3, "type"] = "time"
		fspecs[ 4, "type"] = "int"
		fspecs[ 5, "type"] = "str"  ; fspecs[ 5, "value"] = "END"
		if(chk_fspecs($5, NF, n_fspecs, fspecs)){
			err = 1
			next
		}
	}else if($5 == "Job"){
		# date	time	time	"."	"Job"	string	string	float	("DD"|"PEX")	string
		delete fspecs
		n_fspecs = 10
		fspecs[ 1, "type"] = "date"
		fspecs[ 2, "type"] = "time"
		fspecs[ 3, "type"] = "time"
		fspecs[ 4, "type"] = "str"   ; fspecs[ 4, "value"] = "."
		fspecs[ 5, "type"] = "str"   ; fspecs[ 5, "value"] = "Job"
		fspecs[ 6, "type"] = "str"
		fspecs[ 7, "type"] = "str"
		fspecs[ 8, "type"] = "real"
		fspecs[ 9, "type"] = "regex" ; fspecs[ 9, "value"] = "DD|PEX"
		fspecs[10, "type"] = "str"
		if(chk_fspecs($5, NF, n_fspecs, fspecs)){
			err = 1
			next
		}
	}else if($5 == "Expense"){
		# date	time	time	"."	"Expense"	string	"$"float
		delete fspecs
		n_fspecs = 7
		fspecs[ 1, "type"] = "date"
		fspecs[ 2, "type"] = "time"
		fspecs[ 3, "type"] = "time"
		fspecs[ 4, "type"] = "str"   ; fspecs[ 4, "value"] = "."
		fspecs[ 5, "type"] = "str"   ; fspecs[ 5, "value"] = "Expense"
		fspecs[ 6, "type"] = "str"
		fspecs[ 7, "type"] = "real"
		if(chk_fspecs($5, NF, n_fspecs, fspecs)){
			err = 1
			next
		}
	}else if($5 == "Reject"){
		# date	time	time	"."	"Reject"	string	string	float	("DD"|"PEX")	string
		delete fspecs
		n_fspecs = 10
		fspecs[ 1, "type"] = "date"
		fspecs[ 2, "type"] = "time"
		fspecs[ 3, "type"] = "time"
		fspecs[ 4, "type"] = "str"   ; fspecs[ 4, "value"] = "."
		fspecs[ 5, "type"] = "str"   ; fspecs[ 5, "value"] = "Job"
		fspecs[ 6, "type"] = "str"
		fspecs[ 7, "type"] = "str"
		fspecs[ 8, "type"] = "real"
		fspecs[ 9, "type"] = "regex" ; fspecs[ 9, "value"] = "DD|PEX"
		fspecs[10, "type"] = "str"
		if(chk_fspecs($5, NF, n_fspecs, fspecs)){
			err = 1
			next
		}
	}else{
		printf("ERROR: %s:%d: bad jobType \"%s\"\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, $5)
		err = 1
	}
}
END {
	exit err
}
function chk_fspecs(ltype, nf_have, n_fspecs, fspecs,   f, n_ary, ary, work, i) {
	if(nf_have != n_fspecs) {
		printf("ERROR: %s:%d: %s line: wrong number of fields %d: need %d\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, nf_have, n_fspecs)
		return 1
	}
	for(f = 1; f <= n_fspecs; f++){
		type = fspecs[f, "type"]
		if(type == "date"){		# YYYY-MM-DD
			work = $f
			gsub(/-/, " ", work)
			if(mktime(work " 00 00 00") == -1){
				printf("ERROR: %s:%d: %s line: bad date %s: expect YYYY-MM-DD\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f)
				return 1
			}
		}else if(type == "time"){	# HH:MM
			work = $f
			gsub(/:/, " ", work)
			if(mktime("2015 01 01 " work " 00") == -1){
				printf("ERROR: %s:%d: %s line: bad %s time %s: expect HH:MM\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, f == 2 ? "start" : "end", $f)
				return 1
			}
		}else if(type == "int"){	# [0-9][0-9]*
			if($f !~ /^[0-9[0-9]*$/){
				printf("ERROR: %s:%d: %s line: bad integer %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f)
				return 1
			}
		}else if(type == "real"){	# dollars . cents.  Complain if has leading $
			n_ary = split($f, ary, ".")
			if(n_ary != 2){
				printf("ERROR: %s:%d: %s line: bad money %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f)
				return 1
			}else if(ary[1] !~ /^[0-9][0-9]*$/){
				printf("ERROR: %s:%d: %s line: bad dollar part %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f)
				return 1
			}else if(ary[2] !~ /^[0-9][0-9]$/){
				printf("ERROR: %s:%d: %s line: bad cents %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f)
				return 1
			}
		}else if(type == "str"){	# anything unless has a value
			if((f, "value") in fspecs){
				if($f != fspecs[f, "value"]){
					printf("ERROR: %s:%d: %s line: bad string %s: expect %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f, fspecs[f, "value"])
					return 1
				}
			}
		}else if(type == "regex"){	# value is a regex the string must match
			work = fspecs[f, "value"]
			if(index(work, "|") != 0){
				n_ary = split(work, ary, "|")
				for(i = 1; i <= n_ary; i++){
					if($f ~ ary[i])
						return 0
				}
				printf("ERROR: %s:%d: %s line: bad string %s: does not match %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f, fspecs[f, "value"])
				return 1
			}else if($f !~ work){
				printf("ERROR: %s:%d: %s line: bad string %s: does not match %s\n", FILENAME == "-" ? "_stdin_" : FILENAME, NR, ltype, $f, fspecs[f, "value"])
				return 1
			}
		}else{	# should never happen
			printf("ERROR: unknown type %s\n", type) > "/dev/stderr"
			err = 1
			exit err
		}
	}
	return 0
}' $FILE
