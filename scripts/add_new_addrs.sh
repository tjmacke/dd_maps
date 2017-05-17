#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -f ] runs-file_1 ..."

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts
DM_DB=$DM_ADDRS/dd_maps.db

# Use the last mod date of the DB to select which runs files need to be check for new addresses
if [ ! -s $DM_DB ] ; then
	LOG ERROR "database $DM_DB either does not exist or has zero size"
	exit 1
fi

FORCE=
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

if [ -z "$FORCE" ] ; then
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
	$DM_SCRIPTS/get_addrs_from_runs.sh -at src $nf | $DM_SCRIPTS/insert_new_addrs.sh -at src
	$DM_SCRIPTS/get_addrs_from_runs.sh -at dst $nf | $DM_SCRIPTS/insert_new_addrs.sh -at dst
done
