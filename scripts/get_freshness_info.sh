#! /bin/bash
#
. ~/etc/funcs.sh
export LC_ALL=C

U_MSG="usage: $0 [ -help ] -at { src | dst } runs-file-1 ..."

TMP_RFILE=/tmp/runs.$$

ATYPE=
FILES=

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
	-*)
		LOG ERROR "unknown option $1"
		echo "$U_MSG" 1>&2
		exit 1
		;;
	*)
		if [ ! -z "$FILES" ] ; then
			FILES="$FILES $1"
		else
			FILES=$1
		fi
		shift
		;;
	esac
done

if [ -z "$FILES" ] ; then
	LOG ERROR "no runs-file arguments"
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

echo -e "date\tle1\tle2\tle4\tle8\tle12\tle26\tle52\tgt52"
for f in $FILES ; do
	rdate="$(echo $f | awk -F/ '{ split($NF, ary, ".") ; print ary[2] ; exit 0 }')"
	cat $f | awk -F'\t' '$5 == "Job"' >> $TMP_RFILE
	awk -F'\t' 'BEGIN {
		atype = "'"$ATYPE"'"
		f_addr = atype == "src" ? 6 : 7

		rdate = "'"$rdate"'"

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
		if(!($f_addr in l_visits))
			l_visit[$f_addr] = $1
		else if($1 > l_visits[$f_addr])
			l_visit[$f_addr] = $1
		if(latest == "")
			latest = $1
		else if( $1 > latest)
			latest = $1
	}
	END {
		work = latest
		gsub(/-/, " ", work)
		t_latest = mktime(work " 00 00 00")
		week = 7 * 86400
		for(a in l_visit){
			work = l_visit[a]
			gsub(/-/, " ", work)
			t_visit = mktime(work " 00 00 00")
			n_weeks = (t_latest - t_visit)/week
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
		printf("%s-%s-%s", substr(rdate, 1, 4), substr(rdate, 5, 2), substr(rdate, 7, 2))
		for(i = 1; i <= 8; i++)
			printf("\t%.2f", 100.0 *((h_idx[i] in h_cnt) ?  h_cnt[h_idx[i]] : 0)/total)
		printf("\n")
	}' $TMP_RFILE
done

rm -f $TMP_RFILE
