function AU_init(addr_info, us_states, us_states_long, towns_a2q, towns_r2q, st_types_2qry, dirs_2qry, ords_2qry,    err, ad_counts, ad) {

	err = 0

	# check that we got all the data we need
	ad_counts["n_us_states"] = AU_get_addr_data(addr_info, "us_states", us_states)

	ad_counts["n_towns_a2q"] = AU_get_addr_data(addr_info, "towns_a2q", towns_a2q)
	ad_counts["n_st_types_2qry"] = AU_get_addr_data(addr_info, "st_types_2qry", st_types_2qry)
	ad_counts["n_dirs_2qry"] = AU_get_addr_data(addr_info, "dirs_2qry", dirs_2qry)
	ad_counts["n_ords_2qry"] = AU_get_addr_data(addr_info, "ords_2qry", ords_2qry)

	ad_counts["n_towns_r2q"] = AU_get_addr_data(addr_info, "towns_r2q", towns_r2q)

	for(ad in ad_counts){
		if(ad_counts[ad] == 0){
			printf("ERROR: %s no \"%s\" data\n", ai_file, substr(ad, 3)) > "/dev/stderr"
			err = 1
		}
	}
	if(err)
		return err

	# create a map of full state names
	for(s in us_states)
		us_states_long[us_states[s]] = s

	return err
}

function AU_parse(options, addr, addr_ary, states, states_long, towns, st_types, dirs, st_ords,   nf, ary, i, f_st, f_twn, nf2, ary2, b1, e1, name, street, quals, town, state, work) {

	addr_ary["status"] = "B"
	addr_ary["emsg"  ] = ""
	addr_ary["name"  ] = ""
	addr_ary["street"] = ""
	addr_ary["quals" ] = ""
	addr_ary["town"  ] = ""
	addr_ary["state" ] = ""

	nf = split(addr, ary, ",")
	for(i = 1; i <= nf; i++){
		sub(/^ */, "", ary[i])
		sub(/ *$/, "", ary[i])
	}

	# Some geocoders are US only so the last field is the state or state zip
	if(options["rply"]){
		if(!options["us_only"]){
			if(ary[nf] == "United States of America")
				nf--
			else{
				addr_ary["emsg"] = "not.US"
				return 1
			}
		}
	}

	if(!options["rply"]){
		# As a convenience to the user, given that nearly all the addresses
		# are in small set of nearby towns, the minimal query address can be 
		#
		#	street, TOWN
		#
		# where TOWN is an abbreviation for town, state. Example: PA -> Palo Alto, CA
		if(nf < 2){
			addr_ary["emsg"] = "short.addr.1"
			return 1
		}
		# expand town if needed
		if(ary[nf] in towns){
			nf2 = split(towns[ary[nf]], ary2, ",")
			if(nf2 != 2){
				addr_ary["emsg"] = "bad.town"
				return  1
			}
			for(i = 1; i <= nf2; i++){
				sub(/^  */, "", ary2[i])
				sub(/  *$/, "", ary2[i])
			}
			ary[nf] = ary2[1]
			ary[nf+1] = ary2[2]
			nf++
		}
	}

	# At this point, all addresses must have at least three fields: street, town, state
	if(nf < 3){
		addr_ary["emsg"] = "short.addr.2"
		return 1
	}

	# check for a valid state, ignoring zip code
	if(substr(ary[nf], 1, 2) in states)
		state = ary[nf]
	else if(ary[nf] in states_long)
		state = ary[nf]
	else{
		addr_ary["emsg"] = sprintf("bad.US.state.%s", ary[nf])
		return 1
	}

	town = ary[nf-1]

	f_st = 0

	# find the street:
	# street is the 1st element of ary that begins with an integer and has > 1 one word
	# so, 200 by itself is not a street, but 200 Broadway is
	f_st = 0
	for(i = 1; i < nf - 1; i++){
		nf2 = split(ary[i], ary2, /  */)
		if(ary2[1] ~ /^[1-9][0-9]*$/ && nf2 > 1){
			f_st = i
			break
		}
	}
	if(f_st == 0){
		addr_ary["emsg"] = "no.street.num"
		return 1
	}
	
	# The name is what precedes f_st.  if f_st == 1, set name to user supplied default value
	if(f_st == 1)
		name = options["no_name"]
	else{
		name = ary[1]
		for(i = 2; i < f_st; i++)
			name = name ", " ary[i]
	}

	# Street qualifiers are those fields, if any, that follow f_st and precede nf - 1
	if(nf - f_st > 2){
		quals = ary[f_st+1]
		for(i = f_st+2; i < nf - 1; i++)
			quals = quals ", " ary[i]
	}else
		quals = ""

	# clean up street
	nf2 = split(ary[f_st], ary2, /  */)
	if(nf2 < 2){
		addr_ary["emsg"] = "short.street"
		return 1
	}

	# If a word in street begins w/lower case, upper case it.  Convert, say el Camino to El Camino, etc
	for(i = 2; i <= nf2; i++){
		if(substr(ary2[i], 1, 1) ~ /^[a-z]/)
			ary2[i] = toupper(substr(ary2[i], 1, 1)) substr(ary2[i], 2)
	}

	# Street should be num [ dir ] str [ st ] [ dir ]
	street = ary2[1]
	if(options["do_subs"]){
		# TODO: generalize, as I've now seen an address w/3 words in dir, st_types
		# This is amusing.  What is South Court? Is it S. Court or South Ct.  No idea so leave such streets in long form
		if(nf2 == 3 && (ary2[2] in dirs) && (ary2[3] in st_types)){
			for(i = 2; i <= nf2; i++)
				street = street " " ary2[i]
		}else{
			# handle any leading direction
			if(ary2[2] in dirs){
				street = street " " dirs[ary2[2]]
				b1 = 3
			}else
				b1 = 2

			# detect trailing direction
			e1 = ary2[nf2] in dirs ? nf2-1 : nf2
			for(i = b1; i < e1; i++){
				if(i == b1)
					street = street ((ary2[i] in st_ords) ? (" " st_ords[ary2[i]]) : (" " ary2[i]))
				else
					street = street " " ary2[i]
			}
			street = street ((ary2[e1] in st_types) ? (" " st_types[ary2[e1]]) : (" " ary2[e1]))
			# handle any trailing direction
			if(e1 < nf2)
				street = street " " dirs[ary2[nf2]]
		}
	}else{
		for(i = 2; i <= nf2; i++)
			street = street " " ary2[i]
	}

	if(options["rply"]){
		if(town in towns)
			town = towns[town]
	}

	addr_ary["status"] = "G"
	addr_ary["name"  ] = name
	addr_ary["street"] = street
	addr_ary["quals" ] = quals
	addr_ary["town"  ] = town 
	addr_ary["state" ] = state

	return 0
}

function AU_get_addr_data(addr_info, key, data,   k, keys, nk, i) {

	n_data = 0
	for(k in addr_info){
		nk = split(k, keys, SUBSEP)
		if(keys[1] == key){
			data[keys[2]] = addr_info[k]
			n_data++
		}
	}
	return n_data
}

function AU_match(options, ref, cand,   nc_fields, c_fields, nr_fields, r_fields, i, nc_rtab, c_rtab, nr_rtab, r_rtab, nr_nwords, r_nwords, nc_nwords, c_nwords) {

	if(options["verbose"]){
		printf("ref.name    = %s\n", ref["name"]) > "/dev/stderr"
		printf("ref.street  = %s\n", ref["street"]) > "/dev/stderr"
		printf("ref.town    = %s\n", ref["town"]) > "/dev/stderr"
		printf("ref.state   = %s\n", ref["state"]) > "/dev/stderr"
		printf("cand.name   = %s\n", cand["name"]) > "/dev/stderr"
		printf("cand.street = %s\n", cand["street"]) > "/dev/stderr"
		printf("cand.town   = %s\n", cand["town"]) > "/dev/stderr"
		printf("cand.state  = %s\n", cand["state"]) > "/dev/stderr"
	}

	cand["emsg"] = ""
	if(cand["state"] != ref["state"]){
		if(options["ign_zip"]){
			if(substr(cand["state"], 1, 2) != substr(ref["state"], 1, 2)){
				cand["emsg"] = "states.ign_zip.diff"
				return 0
			}
		}else{
			cand["emsg"] = "states.diff"
			return 0
		}
	}

	if(cand["town"] != ref["town"]){
		cand["emsg"] = "towns.diff"
		return 0
	}

	# street numbers and/or ranges, etc is 1st field
	nc_fields = split(cand["street"], c_fields, /  */)
	nr_fields = split(ref["street"], r_fields, /  */)

	# check that non-number parts of streets agree
	if(nc_fields != nr_fields){
		cand["emsg"] = "num.st.fields.diff"
		return 0
	}
	for(i = 2; i <= nc_fields; i++){
		if(c_fields[i] != r_fields[i]){
			cand["emsg"] = sprintf("st.field.%d.diff|%s|%s", i, c_fields[i], r_fields[i])
			return 0
		}
	}

	nc_rtab = AU_get_rtab(c_fields[1], c_rtab)
	if(nc_rtab == 0){
		cand["emsg"] = "nc_rtab.is.zero"
		return 0
	}

	nr_rtab = AU_get_rtab(r_fields[1], r_rtab)
	if(nr_rtab == 0){
		cand["emsg"] = "nr_rtab.is.zero"
		return 0
	}

	if(!AU_rtabs_intersect(nc_rtab, c_rtab, nr_rtab, r_rtab)){
		cand["emsg"] = "rtab.no.ovlp"
		return 0
	}

	# deal with names
	if(cand["name"] == ref["name"]){
		return 3
	}else if(cand["name"] == ""){	# this is an unannotated address
		return 1
	}else if(ref["name"] == options["no_name"]){	# many destinations are just street, town, state
		return 1
	}else{	# check if 1st words match; but no matter what this is a match
		nc_nwords = split(cand["name"], c_nwords, /  */)
		nr_nwords = split(ref["name"], r_nwords, /  */)
		return c_nwords[1] == r_nwords[1] ? 2 : 1
	}
}

function AU_get_rtab(street, rtab,   n_rtab, i, nw, work, l_pfx, e_work2) {

	n_rtab = split(street, rtab, ";")
	for(i = 1; i <= n_rtab; i++){
		nw = split(rtab[i], work, "-")
		if(nw > 1){
			rtab[i, 1] = work[1] + 0	# force number
			rtab[i, 2] = work[2] + 0	# force number

			if(rtab[i,1] > rtab[i,2]){
				# Is this a "delta" range where the 2d value shows only the different address suffix?
				# If so try to fix it
				# For example 945-51 would be expanded to 945-951 which is good, but
				# 945-37 would be expanded to 945-937 which is still wrong.
				l_pfx = length(work[1]) - length(work[2])
				e_work2 = ((l_pfx > 0) ? ((substr(work[1], 1, l_pfx) work[2])) : work[2]) + 0
				# did we fix it?
				if(rtab[i, 1] > e_work2){
					printf("ERROR: bad range 1st precedes 2nd: %d-%d\n", rtab[i, 1], rtab[i, 2]) > "/dev/stderr"
					return 0
				}else
					rtab[i, 2] = e_work2
			}

			rtab[i, "rng"] = 1
			if(rtab[i, 1] % 2 != rtab[i, 2] % 2){
				printf("ERROR: bad range: odd/even %d-%d\n", rtab[i, 1], rtab[i, 2]) > "/dev/stderr"
				return 0
			}
		}else{
			rtab[i] = work[1] + 0	# force number
			rtab[i, "rng"] = 0
		}
	}
	return n_rtab
}

function AU_rtabs_intersect(n_rtab1, rtab1, n_rtab2, rtab2,   i, j) {

	# the most common case: number v number
	if(n_rtab1 == 1 && !rtab1[1, "rng"] && n_rtab2 == 1 && !rtab2[1, "rng"])
		return rtab1[1] == rtab2[1]

	for(i = 1; i <= n_rtab1; i++){
		for(j = 1; j <= n_rtab2; j++){
			if(!rtab1[i, "rng"]){
				if(!rtab2[j, "rng"]){	# number v number
					if(rtab1[i] == rtab2[j])
						return 1
				}else{			# number v range
					if(rtab1[i] >= rtab2[j, 1] && rtab1[i] <= rtab2[j, 2])
						return 1
				}
			}else if(!rtab2[j, "rng"]){	# range v number
				if(rtab2[j] >= rtab1[i, 1] && rtab2[j] <= rtab1[i, 2])
					return 1
			}else{				# range v range
				if(!(rtab1[i, 2] < rtab2[j, 1] || rtab1[i, 1] > rtab2[j, 2]))
					return 1
			}
		}
	}
	return 0
}

function AU_rtab_dump(file, n_rtab, rtab,   i) {
	
	printf("n_rtab = %d {\n", n_rtab) > file
	for(i = 1; i <= n_rtab; i++){
		if(rtab[i, "rng"])
			printf("\trtab[%d, 1-2] = %d-%d\n", i, rtab[i, 1], rtab[i, 2]) > file 
		else
			printf("\trtab[%d     ] = %d\n", i, rtab[i]) > file 
	}
	printf("}\n") > file
}
