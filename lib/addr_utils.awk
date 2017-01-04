function AU_parse(rply, do_subs, addr, result, towns, st_types, st_quals, dirs,   nf, ary, i, f_st, nf2, ary2, i1, name, street, quals, town, k) {

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

	if(rply){
		# TODO: generalize to all states?
		if(ary[nf] != "United States of America"){
			result["emsg"] = "not.usa"
			return 1
		}else
			nf--
		if(ary[nf] == "CA")
			nf--
		else if(ary[nf] ~ /CA [0-9]{5}$/)
			nf--
		else if(ary[nf] ~ /CA [0-9]{5}-[0-9]{4}$/)
			nf--
		else if(ary[nf] == "California")
			nf--
		else{
			result["emsg"] = "not.CA"
			return 1
		}
	}

	# minimal address has 2 fields: street, town
	if(nf < 2){
		result["emsg"] = "short.addr"
		return 1
	}

	# check that we have a known town
	if(!(ary[nf] in towns)){
		result["emsg"] = "bad.town"
		return 1
	}
	town = do_subs ? towns[ary[nf]] : ary[nf]

	# find the street.
	# street is 1) 1st elt of ary[1:nf-1] that begins w/number & ends w/st_type or 2) last elt of ary[1:nf-1] that begins w/number
	f_st = 0
	for(i = 1; i < nf; i++){
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
	
	# The name is what precedes f_st.  if f_st == 1, set name to "Residence"
	if(f_st == 1)
		name = "Residence"
	else{
		name = ary[1]
		for(i = 2; i < f_st; i++)
			name = name ", " ary[i]
	}

	# Street qualifiers are those fields, if any, that follow f_st and precede nf
	if(nf - f_st > 1){
		quals = ary[f_st+1]
		for(i = f_st+2; i < nf; i++)
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
	if(do_subs){
		if(nf2 > 3){
			if(ary2[nf2-2] == "el" && ary2[nf2-1] == "Camino")
				ary2[nf2-2] = "El"
			else if(ary2[nf2-2] == "el" && ary2[nf2-1] == "Monte")
				ary2[nf2-2] =  "El"
		}
	}

	# Street should be num [ dir ] str [ st ]
	street = ary2[1]
	if(do_subs){
		# This is amusing.  What is South Court? Is is S. Court or South Ct.  No idea so, leave such streets in long form
		if(nf2 == 3 && (ary2[2] in dirs) && (ary2[3] in st_types)){
			for(i = 2; i <= nf2; i++)
				street = street " " ary2[i]
		}else{
			if(ary2[2] in dirs){
				street = street " " dirs[ary2[2]]
				i1 = 3
			}else
				i1 = 2
			for(i = i1; i < nf2; i++){
				street = street " " ary2[i]
			}
			street = street ((ary2[nf2] in st_types) ? (" " st_types[ary2[nf2]]) : (" " ary2[nf2]))
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
	result["state" ] = "CA"

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
function AU_match(cand, ref,   is_mat, i, n_cand_st, cand_st, cand_odd, n_ref_st, ref_st, ref_odd) {

	is_mat = 0

	# deal with street ranges
	n_cand_st = split(cand["street"], cand_st, /-/)
	n_ref_st = split(ref["street"], ref_st, /-/)

	# US rule: require all numbers to be either odd or even
	cand_odd = cand_st[1] % 2
	for(i = 2; i <= n_cand_st; i++){
		if(cand_st[i] % 2 != cand_odd){
			printf("ERROR: odd/even candidate address range: %s\n", cand["street"]) > "/dev/stderr"
			return 0
		}
	}
	n_ref_st = split(ref["street"], ref_st, /-/)
	ref_odd = ref_st[1] % 2
	for(i = 2; i <= n_ref_st; i++){
		if(ref_st[i] % 2 != ref_odd){
			printf("ERROR: odd/even reference address range: %s\n", ref["street"]) > "/dev/stderr"
			return 0
		}
	}
	if(cand_odd != ref_odd)
		return 0

	# odd/even good, check the actual numbers/ranges
	if(n_cand_st == 1){
		if(n_ref_st == 1){
			is_mat = cand_st[1] == ref_st[1]
		}else{
			is_mat = cand_st[1] >= ref_st[1] && cand_st[1] <= ref_st[2]
		}
	}else if(n_ref_st == 1){
		is_mat = ref_st[1] >= cand_st[1] && ref_st[1] <= cand_st[2]
	}else{
		is_mat = !(cand_st[2] < ref_st[1] || cand_st[1] > ref_st[2])
	}

	# streets are good, deal with towns
	if(is_mat){
		is_mat = cand["town"] == ref["town"]
	}

	return is_mat
}
function AU_match_2(cand, ref,   n_cand_fields, cand_fields, n_ref_fields, ref_fields, i, n_cand_rtab, cand_rtab, n_ref_rtab, ref_rtab) {

	# street numbers and/or ranges, etc is 1st field
	n_cand_fields = split(cand["street"], cand_fields, /  */)
	n_ref_fields = split(ref["street"], ref_fields, /  */)

	# check that non-number parts of streets agree
	if(n_cand_fields != n_ref_fields)
		return 0
	for(i = 2; i <= n_cand_fields; i++){
		if(cand_fields[i] != ref_fields[i])
			return 0
	}

	n_cand_rtab = AU_get_rtab(cand_fields[1], cand_rtab)
	if(n_cand_rtab == 0)
		return 0

	n_ref_rtab = AU_get_rtab(ref_fields[1], ref_rtab)
	if(n_ref_rtab == 0)
		return 0

	if(!AU_rtabs_intersect(n_cand_rtab, cand_rtab, n_ref_rtab, ref_rtab))
		return 0

	return cand["town"] = ref["town"]
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
