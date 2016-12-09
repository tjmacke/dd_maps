function AU_parse(rply, addr, result, towns, st_types, st_quals, dirs,   nf, ary, i, f_st, nf2, ary2, i1, name, street, town) {

	result["status"] = "B"
	result["emsg"  ] = ""
	result["name"  ] = ""
	result["street"] = ""
	result["town"  ] = ""
	result["state" ] = ""

	nf = split(addr, ary, ",")
	for(i = 1; i <= nf; i++){
		sub(/^ */, "", ary[i])
		sub(/ *$/, "", ary[i])
	}

	if(rply){
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
	town = towns[ary[nf]]

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

	# TODO: reply addresses need extra thought here
	# clean up street
	nf2 = split(ary[f_st], ary2, /  */)
	if(nf2 < 2){
		result["emsg"] = "short.street"
		return 1
	}

	# Street should be num [ dir ] str [ st ]
	street = ary2[1]
	if(ary2[2] in dirs){
		street = street " " dirs[ary2[2]]
		i1 = 3
	}else
		i1 = 2
	for(i = i1; i < nf2; i++){
		street = street " " ary2[i]
	}
	street = street ((ary2[nf2] in st_types) ? (" " st_types[ary2[nf2]]) : (" " ary2[nf2]))

	result["status"] = "G"
	result["name"] = name
	result["street"] = street
	result["town"] = town
	result["state"] = "CA"

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
