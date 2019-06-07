#! /bin/bash
#

# geocoder defs
GEO_PRIMARY=geo		# geocod.io: free 2500/day
GEO_SECONDARY=ocd	# opencagedata.com: free 2500/day
GEO_TERTIARY=ss		# smartystreets.com: free 250/month!

function chk_geocoders {

	echo $* |
	awk 'BEGIN {
		k_geos["'"$GEO_PRIMARY"'"] = 1
		k_geos["'"$GEO_SECONDARY"'"] = 1
		k_geos["'"$GEO_TERTIARY"'"] = 1
	}
	{
		n_ary = split($0, ary, ",")
		for(i = 1; i <= n_ary; i++){
			sub(/^  */, "", ary[i])
			sub(/  *$/, "", ary[i])
			if(!(ary[i] in k_geos)){
				print "ERROR: unknown geocoder: " ary[i]
				exit 1
			}
			if(!(ary[i] in u_geos)){
				u_geos[ary[i]] = 1
				nu_gtab++
				u_gtab[nu_gtab] = ary[i]
			}
		}
		g_list = ""
		for(i = 1; i <= nu_gtab; i++)
			g_list = g_list (i > 1 ? "," : "") u_gtab[i]
		print g_list
	}'
}
