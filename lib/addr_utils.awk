function AU_parse(options, addr, result, states, towns, st_types, dirs, st_ords,   nf, ary, i, f_st, f_twn, nf2, ary2, b1, e1, name, street, quals, town, state, k) {

	result["status"] = "B"
	result["emsg"  ] = ""
	result["name"  ] = ""
	result["street"] = ""
	result["quals" ] = ""
	result["town"  ] = ""
	result["state" ] = ""

	nf = split(addr, ary, ",")
	for(i = 1; i <= nf; i++){
		sub(/^ */, "", ary[i])
		sub(/ *$/, "", ary[i])
	}

	# US only for now
	if(ary[nf] == "United States of America")
		nf--

	# Every address for now must after possible "town expansion" match this pattern:
	#
	# 	[ name, ] street, [ quals, ] town, state
	#
	# Since most of the addresses sent to this parser are from a small set of towns,
	# the user can define town abbreviations that will be expanded into town, state,
	# which means that the mininal input address must have at least two fields.
	#
	if(nf < 2){
		result["emsg"] = "short.addr"
		return 1
	}
	# expand town if needed
	if(ary[nf] in towns){
		nf2 = split(towns[ary[nf]], ary2, ",")
		if(nf2 != 2){
			result["emsg"] = "bad.town"
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
	# At this point, all addresses must have at least three fields.
	if(nf < 3){
		result["emsg"] = "short.addr"
		return 1
	}

	# check for a valid state:
	if(!(ary[nf] in states)){
		result["emsg"] = "not.US"
		return 1
	}else
		state = ary[nf]
	town = ary[nf-1]

	# find the street.
	# street is 1) 1st elt of ary[1:nf-2] that begins w/number & ends w/st_type or 2) last elt of ary[1:nf-2] that begins w/number
	f_st = 0
	for(i = 1; i < nf - 1; i++){
		if(ary[i] ~ /^[1-9]/){
			nf2 = split(ary[i], ary2, /  */)
			if(ary2[nf2] in st_types){
				f_st = i
				break
			}
			f_st = i
		}
	}
	if(f_st == 0){
		result["emsg"] = "no.street"
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

	# Street qualifiers are those fields, if any, that follow f_st and precede nf
	if(nf - f_st > 2){
		quals = ary[f_st+1]
		for(i = f_st+2; i < nf - 1; i++)
			quals = quals ", " ary[i]
	}else
		quals = ""

	# clean up street
	nf2 = split(ary[f_st], ary2, /  */)
	if(nf2 < 2){
		result["emsg"] = "short.street"
		return 1
	}

	# Street Hacks: Probably should just compare ignore case but not ready for that step yet
	# change el Camino X to El Camino X
	# change el Monte X  to El Monte X
	if(options["do_subs"]){
		if(nf2 > 3){
			if(ary2[nf2-2] == "el" && ary2[nf2-1] == "Camino")
				ary2[nf2-2] = "El"
			else if(ary2[nf2-2] == "el" && ary2[nf2-1] == "Monte")
				ary2[nf2-2] =  "El"
		}
	}

	# Street should be num [ dir ] str [ st ] [ dir ]
	street = ary2[1]
	if(options["do_subs"]){
		# This is amusing.  What is South Court? Is is S. Court or South Ct.  No idea so leave such streets in long form
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

	result["status"] = "G"
	result["name"  ] = name
	result["street"] = street
	result["quals" ] = quals
	result["town"  ] = town 
	result["state" ] = state

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
function AU_match(options, cand, ref,   nc_fields, c_fields, nr_fields, r_fields, i, nc_rtab, c_rtab, nr_rtab, r_rtab, nr_nwords, r_nwords, nc_nwords, c_nwords) {

	if(options["verbose"]){
		printf("ref.name    = %s\n", ref["name"]) > "/dev/stderr"
		printf("ref.street  = %s\n", ref["street"]) > "/dev/stderr"
		printf("cand.name   = %s\n", cand["name"]) > "/dev/stderr"
		printf("cand.street = %s\n", cand["street"]) > "/dev/stderr"
	}

	# street numbers and/or ranges, etc is 1st field
	nc_fields = split(cand["street"], c_fields, /  */)
	nr_fields = split(ref["street"], r_fields, /  */)

	# check that non-number parts of streets agree
	if(nc_fields != nr_fields)
		return 0
	for(i = 2; i <= nc_fields; i++){
		if(c_fields[i] != r_fields[i])
			return 0
	}

	nc_rtab = AU_get_rtab(c_fields[1], c_rtab)
	if(nc_rtab == 0)
		return 0

	nr_rtab = AU_get_rtab(r_fields[1], r_rtab)
	if(nr_rtab == 0)
		return 0

	if(!AU_rtabs_intersect(nc_rtab, c_rtab, nr_rtab, r_rtab))
		return 0

	if(cand["town"] != ref["town"])
		return 0
	else if(cand["name"] == ref["name"]){
		return 3
	}else if(cand["name"] == ""){	# this is unannotated address
		return 1
	}else if(ref["name"] == "Residence"){	# many destinations are just street, town
		return 1
	}else{	# check if 1st words match
		nc_nwords = split(cand["name"], c_nwords, /  */)
		nr_nwords = split(ref["name"], r_nwords, /  */)
		return c_nwords[1] == r_nwords[1] ? 2 : 0
	}
}
function AU_get_rtab(street, rtab,   n_rtab, i, nw, work) {

	n_rtab = split(street, rtab, ";")
	for(i = 1; i <= n_rtab; i++){
		nw = split(rtab[i], work, "-")
		if(nw > 1){
			rtab[i, 1] = work[1] + 0	# force number
			rtab[i, 2] = work[2] + 0	# force number
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
