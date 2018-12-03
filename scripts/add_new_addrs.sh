#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -f ] -db db-file runs-file_1 ..."

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
# set these from the cmd line
#DM_ADDRS=$DM_HOME/addrs
#DM_DB=$DM_ADDRS/dd_maps.db

# Use the last mod date of the DB to select which runs files need to be check for new addresses
#if [ ! -s $DM_DB ] ; then
#	LOG ERROR "database $DM_DB either does not exist or has zero size"
#	exit 1
#fi

FORCE=
DM_DB=
FILES=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-f)
		FORCE="yes"
		shift
		;;
	-db)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-db requires db-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		DM_DB=$1
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
	LOG ERROR "no runs-files specified"
	echo "$U_MSG" 1>&2
	exit 1
fi

if [ -z "$DM_DB" ] ; then
	LOG ERROR "missing -db db-file argument"
	echo "$U_MSG" 1>&2
	exit 1
elif [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exit or has zero size"
	exit 1
fi

if [ "$FORCE" = "yes" ] ; then
	N_FILES=
	t_db=$(date -r $DM_DB +%s)
	for f in $FILES ; do
		t_f=$(date -r $f +%s)
		if [ $t_db -le $t_f ] ; then
			if [ ! -z "$N_FILES" ] ; then
				N_FILES="$N_FILES $f"
			else
				N_FILES=$f
			fi
		fi
	done
else
	N_FILES="$FILES"
fi

for nf in $N_FILES ; do
	$DM_SCRIPTS/get_addrs_from_runs.sh -at src $nf | $DM_SCRIPTS/insert_new_addrs.sh -db $DM_DB -at src
	$DM_SCRIPTS/get_addrs_from_runs.sh -at dst $nf | $DM_SCRIPTS/insert_new_addrs.sh -db $DM_DB -at dst
done
