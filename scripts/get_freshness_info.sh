#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -at { src | dst } -ts { day | week | month* } [ runs-file ]"

TMP_RFILE=/tmp/runs.$$

ATYPE=
TSTEP=month
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-at)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-at requires address-type argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		ATYPE=$1
		shift
		;;
	-ts)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-ts requires time-step argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		TSTEP=$1
		shift
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

if [ -z "$ATYPE" ] ; then
	LOG ERROR "missing -at address-type argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ "$ATYPE" != "src" ] && [ "$ATYPE" != "dst" ] ; then
	LOG ERROR "unknown address type $ATYPE, must be src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ "$TSTEP" != "day" ] && [ "$TSTEP" != "week" ] && [ "$TSTEP" != "month" ] ; then
	LOG ERROR "unknown time step $TSTEP, must be day, week, month"
	echo "$U_MSG" 1>&2
	exit 1
fi

awk -F'\t' '$5 == "Job"' $FILE	|\
sort -t $'\t' -k 1,1		|\
awk -F'\t' 'BEGIN {
	pr_hdr = 1
	atype = "'"$ATYPE"'"
	tstep = "'"$TSTEP"'"
	f_atype = atype == "src" ? 6 : 7

	t_start = -1
	h_idx[1] = "le1"
	h_idx[2] = "le2"
	h_idx[3] = "le4"
	h_idx[4] = "le8"
	h_idx[5] = "le12"
	h_idx[6] = "le26"
	h_idx[7] = "le52"
	h_idx[8] = "gt52"
}
{
	if(s_date == ""){
		if(tstep != "month")
			s_date = $1
		else
			s_date = substr($1, 1, 8) "01"
	}
	c_date = $1

	while((ns_date = need_upd(s_date, c_date, tstep))){
		if(pr_hdr){
			pr_hdr = 0
			printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "date", "le1", "le2", "le4", "le8", "le12", "le26", "le52", "gt52")
		}
		print_upd(s_date, ns_date, l_visits, h_idx)
		s_date = ns_date
	}

	l_visits[$f_atype] = c_date
}
END {
	if(pr_hdr){
		pr_hdr = 0
		printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "date", "le1", "le2", "le4", "le8", "le12", "le26", "le52", "gt52")
	}
	print_upd(s_date, c_date, l_visits, h_idx)
}
function need_upd(s_date, c_date, tstep,   s_ary, s_mon, c_ary, n_days, l_hour, ts_date, hour, adj, tc_date, t_maxdiff, ns_date) {

	split(s_date, s_ary, "-")
	split(c_date, c_ary, "-")
	if(tstep == "month"){
		if(s_ary[2] == c_ary[2])
			return ""
		s_mon = s_ary[2] + 0
		if(s_mon < 12)
			return s_ary[1] "-" sprintf("%02d", (s_mon + 1)) "-01"
		else
			return (s_ary[1] + 1) "-01-01"
	}else if(tstep == "week")
		n_days = 7
	else
		n_days = 1
	l_hour = 8
	ts_date = mktime(s_ary[1] " " s_ary[2] " " s_ary[3] " 08 00 00")
	hour = strftime("%H", ts_date + n_days * 86400) + 0
	if(hour - l_hour < 0)
		adj = 3600
	else if(hour - l_hour > 0)
		adj = -3600
	else
		adj = 0
	t_maxdiff = n_days * 86400 + adj
	tc_date = mktime(c_ary[1] " " c_ary[2] " " c_ary[3] " 08 00 00")
	if(tc_date < ts_date + t_maxdiff)
		return ""
	ns_date = strftime("%Y-%m-%d", ts_date + t_maxdiff)
	return ns_date
}
function print_upd(s_date, now, l_visits, h_idx,   work, t_now, v, t_visit, n_weeks, h_cnt, total) {
	
	work = now
	gsub(/-/, " ", work)
	t_now = mktime(work " 08 00 00")

	for(v in l_visits){
		work = l_visits[v]
		gsub(/-/, " ", work)
		t_visit = mktime(work " 00 00 00")
		n_weeks = (t_now - t_visit)/(7*86400)
		if(n_weeks <= 1)
			h_cnt["le1"]++
		else if(n_weeks <= 2)
			h_cnt["le2"]++
		else if(n_weeks <= 4)
			h_cnt["le4"]++
		else if(n_weeks <= 8)
			h_cnt["le8"]++
		else if(n_weeks <= 12)
			h_cnt["le12"]++
		else if(n_weeks <= 26)
			h_cnt["le26"]++
		else if(n_weeks <= 52)
			h_cnt["le52"]++
		else
			h_cnt["gt52"]++
	}

	total = 0
	for(i = 1; i <= 8; i++)
		total += (h_idx[i] in h_cnt) ? h_cnt[h_idx[i]] : 0

	printf("%s", s_date)
	for(i = 1; i <= 8; i++)
		printf("\t%.2f", 100.0 *((h_idx[i] in h_cnt) ?  h_cnt[h_idx[i]] : 0)/total)
	printf("\n")
}'

rm -f $TMP_RFILE
