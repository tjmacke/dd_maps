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
		n_fields["BEGIN"] = 7
		n_fields["END"  ] = 5
		n_fields["Job"  ] = 10
		pr_hdr = 1
	}
$1 != "Date" {
	if($1 != l_1){
		if(l_1 != ""){
			if(pr_hdr){
				pr_hdr = 0
				printf("%s\t%s\t%s\t%s\t%s\n", "Date", "Hours", "Miles", "Jobs", "Amount")
			}
			printf("%s\t%.2f\t%d\t%d\t%.2f\n", l_1, t_diff(t_end, t_begin), m_end - m_begin, n_jobs, amt)
			delete lines
			n_lines = 0
			l_begin = l_end = 0
			t_begin = t_end = 0
			m_begin = m_end = 0
			n_jobs = 0
			amt = 0
		}
	}
	n_lines++
	lines[n_lines] = $0
	if($5 == "BEGIN"){
		if(NF != n_fields[$5]){
			printf("%s: ERROR: line %7d: %s line with wrong number fields %d, need %d\n", ARGV[1], NR, $5, NF, n_fields[$5]) > "/dev/stderr"
			exit 1
		}
		l_begin = n_lines
		t_begin = $2
		m_begin = $4
	}else if($5 == "END"){
		if(NF != n_fields[$5]){
			printf("%s: ERROR: line %7d: %s line with wrong number fields %d, need %d\n", ARGV[1], NR, $5, NF, n_fields[$5]) > "/dev/stderr"
			exit 1
		}
		l_end = n_lines
		t_end = $3
		m_end = $4
	}else if($5 == "Job"){
		if(NF != n_fields[$5]){
			printf("%s: ERROR: line %7d: %s line with wrong number fields %d, need %d\n", ARGV[1], NR, $5, NF, n_fields[$5]) > "/dev/stderr"
			exit 1
		}
		n_jobs++
		amt += $8
	}else if($5 == "Reject" ){
	}else if($5 == "Expense" ){
	}else{
		printf("%s: ERROR: line %7d: unknown jobtype \"%s\"\n", ARGV[1], NR, $5) > "/dev/stderr"
	}
	l_1 = $1
}
END {
	if(l_1 != ""){
		if(pr_hdr){
			pr_hdr = 0
			printf("%s\t%s\t%s\t%s\t%s\n", "Date", "Hours", "Miles", "Jobs", "Amount")
		}
		printf("%s\t%.2f\t%d\t%d\t%.2f\n", l_1, t_diff(t_end, t_begin), m_end - m_begin, n_jobs, amt)
		delete lines
		n_lines = 0
		l_begin = 0
		l_end = 0
		n_jobs = 0
		amt = 0
	}
}
function t_diff(t_end, t_start,  ary, end, start){

	split(t_end, ary, ":")
	end = 60*ary[1] + ary[2]

	split(t_start, ary, ":")
	start = 60*ary[1] + ary[2]

	return (end - start)/60
}' $FILE
