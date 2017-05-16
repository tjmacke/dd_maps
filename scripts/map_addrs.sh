#! /bin/bash
#
. ~/etc/funcs.sh

U_MSG="usage: $0 [ -help ] [ -cb_cfg cb-cfg-file ] -at { src | dst } [ address-file ]"

if [ -z "$DM_HOME" ] ; then
	LOG ERROR "DM_HOME is not defined"
	exit 1
fi
DM_ADDRS=$DM_HOME/addrs
DM_ETC=$DM_HOME/etc
DM_LIB=$DM_HOME/lib
DM_SCRIPTS=$DM_HOME/scripts

# TODO: fix this evil dependency
JU_HOME=$HOME/json_utils
JU_BIN=$JU_HOME/bin

TMP_XFILE=
TMP_JFILE=

# awk v3 does not support include
AWK_VERSION="$(awk --version | awk '{ nf = split($3, ary, /[,.]/) ; print ary[1] ; exit 0 }')"
if [ "$AWK_VERSION" == "3" ] ; then
	AWK="igawk --re-interval"
	CFG_UTILS="$DM_LIB/cfg_utils.awk"
elif [ "$AWK_VERSION" == "4" ] ; then
	AWK=awk
	CFG_UTILS="\"$DM_LIB/cfg_utils.awk\""
else
	LOG ERROR "unsupported awk version \"$AWK_VERSION\", must be 3 or 4"
	exit 1
fi

CB_CFG==
ATYPE=
FILE=

while [ $# -gt 0 ] ; do
	case $1 in
	-help)
		echo "$U_MSG"
		exit 0
		;;
	-cb_cfg)
		shift
		if [ $# -eq 0 ] ; then
			LOG ERROR "-cb_cfg requires cf-cfg-file argument"
			echo "$U_MSG" 1>&2
			exit 1
		fi
		CB_CFG="$1"
		shift
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
	LOG ERROR "unknown address type $ATYPE, must src or dst"
	echo "$U_MSG" 1>&2
	exit 1
fi

rval=0

if [ ! -z "$CB_CFG" ] ; then
	if [ -z "$CB_HOME" ] ; then
		LOG ERROR "CB_HOME must be defined to use cartographic boundary information"
		exit 1
	fi
	CB_DATA=$CB_HOME/data
	CB_BIN=$CB_HOME/bin
	if [ -z "$FM_HOME" ] ; then
		LOG ERROR "FM_HOME must be defined to use cartographic boundary information"
		exit 1
	fi
	FM_BIN=$FM_HOME/bin
	TMP_XFILE=/tmp/cb.sh.$$
	TMP_JFILE=/tmp/cb.json.$$
	$AWK '
	@include '"$CFG_UTILS"'
	BEGIN {
		apos = sprintf("%c", 39)

		cb_bin = "'"$CB_BIN"'"
		cb_data = "'"$CB_DATA"'"
		fm_bin = "'"$FM_BIN"'"

		tmp_kfile = "/tmp/kml.$$" 

		cb_cfg = "'"$CB_CFG"'"
		if(CFG_read(cb_cfg, cfg)){
			err = 1
			exit err
		}
	}
	END {
		if(err)
			exit err

		fmap = cfg["_globals", "fmap"]
		if(fmap == ""){
			printf("ERROR: fmap is not set\n") > "/dev/stderr"
			err = 1
			exit err
		}
		n_fm_ary = split(fmap, fm_ary, "/")
		if(fm_ary[1] == "$CB_DATA")
			fm_ary[1] = cb_data
		x_fmap = fm_ary[1]
		for(i = 2; i <= n_fm_ary; i++)
			x_fmap = x_fmap "/" fm_ary[i]

		klist = cfg["_globals", "klist"]
		if(klist == ""){
			printf("ERROR: klist is not set\n") > "/dev/stderr"
			err = 1
			exit err
		}

		kfmt = cfg["_globals", "kfmt"]
		if(kfmt == ""){
			printf("ERROR: kfmt is not set\n") > "/dev/stderr"
			err = 1
			exit err
		}

		kcolor = cfg["_globals", "kcolor"]

		kpat = cfg["_globals", "kpat"]
		kfile = cfg["_globals", "kfile"]
		if(kpat != "" && kfile != ""){
			printf("ERROR: Use only one of kpat, kfile\n") > "/dev/stderr"
			err = 1
			exit err
		}else if(kpat == "" && kfile == ""){
			printf("ERROR: Neither kpat or kfile is set\n") > "/dev/stderr"
			err = 1
			exit err
		}

		printf("#! /bin/bash\n")
		printf("#\n")
		if(kpat){
			kf_list = fm_ary[1]
			for(i = 2; i < n_fm_ary; i++)
				kf_list = kf_list "/" fm_ary[i]
			kf_list = kf_list "/*.keys"
			printf("cat %s |\\\n", kf_list)
			printf("grep %s%s%s |\\\n", apos, kpat, apos)
		}else
			printf("cat %s |\\\n", kfile)
		printf("%s/getentry -md5 -fmap %s %s > %s\n", fm_bin, x_fmap, kfile, tmp_kfile)
		printf("%s/kml2geojson -klist \"%s\" -kfmt %s%s%s 2> /dev/null", cb_bin, klist, apos, kfmt, apos)
		if(kcolor != "")
			printf(" -kcolor %s", kcolor)
		printf(" %s\n", tmp_kfile)

		printf("rm -f %s\n", tmp_kfile)

		exit 0
	}' < /dev/null > $TMP_XFILE
	rval=$?
	if [ $rval -ne 0 ] ; then
		LOG ERROR "polygon extraction script creation failed"
	elif [ ! -s $TMP_XFILE ] ; then
		LOG ERROR "empty polygon extraction script"
		rval=1
	else
		chmod +x $TMP_XFILE
		$TMP_XFILE | $JU_BIN/json_get -g '{geojson}{features}[1:$]' > $TMP_JFILE
	fi
fi

awk -F'\t' 'BEGIN {
	atype = "'"$ATYPE"'"
	f_addr = atype == "src" ? 2 : 3

	jfile = "'"$TMP_JFILE"'"
	if(jfile != ""){
		for(n_cbtab = 0; (getline < jfile) > 0; ){
			n_cbtab++
			cbtab[n_cbtab] = $0
		}
		close(jfile)
	}else
		n_cbtab = 0
}
{
	n_pts++
	date[n_pts] = $1
	q_addr[n_pts] = $f_addr
	lng[n_pts] = $4
	lat[n_pts] = $5
	r_addr[n_pts] = $6
}
END {
	if(n_pts == 0)
		exit 0

	pr_header()
	for(cb = 1; cb <= n_cbtab; cb++)
		printf("%s,\n", cbtab[cb])
	for(p = 1; p <= n_pts; p++){
		printf("{\n")
		printf("  \"type\": \"Feature\",\n")
		printf("  \"geometry\": {\"type\": \"Point\", \"coordinates\": [%.7f, %.7f]},\n", lng[p], lat[p])
		printf("  \"properties\": {\n")
		printf("    \"title\": \"%s\",\n", q_addr[p])
		printf("    \"marker-size\": \"small\",\n")
		printf("    \"marker-color\": \"#aae\"\n")
		printf("  }\n")
		printf("}%s\n", p < n_pts ? "," : "")
	}
	pr_trailer()
	exit 0
}
function pr_header() {

	printf("{\n")
	printf("\"geojson\": {\n")
	printf("\"type\": \"FeatureCollection\",\n")
	printf("\"metadata\": {\n")
	printf("  \"generated\": \"%s\",\n", strftime("%Y%m%dT%H%M%S%Z"))
	printf("  \"title\": \"geo check\",\n" )
	printf("  \"count\": %d\n", n_pts)
	printf("},\n")
	printf("\"features\": [\n")
}
function pr_trailer() {
	printf("]\n")
	printf("}\n")
	printf("}\n")
}' $FILE

if [ ! -z "$TMP_XFILE" ] ; then
	rm -f $TMP_XFILE $TMP_JFILE 
fi

exit $rval
