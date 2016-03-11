function parse_address(addr, result, dirs, st_abbrevs, st_quals, towns,   nf, ary, i, f_st, f_town, name) {

	result["status"] = "B"
	result["emsg"  ] = ""
	result["name"  ] = ""
	result["street"] = ""
	result["town"  ] = ""
	result["state" ] = ""

	nf = split(addr, ary, ",")
	for(i = 1; i <= nf; i++){
		gsub(/^  */, "", ary[i])
		gsub(/  *$/, "", ary[i])
	}
	f_st = get_street(nf, ary, result, dirs, st_abbrevs)
	if(f_st == 0)
		return 1

	f_town = get_town(nf, ary, result, f_st, st_quals, towns)
	if(f_town == 0)
		return 1

	# If we get here, addr is good, set the name
	result["status"] = "G"
	if(f_st == 1)
		result["name"] = "Residence"
	else{
		name = ary[1]
		for(i = 2; i < f_st; i++){
			name = name ", " ary[i]
		}
		result["name"] = name
	}
	return 0
}
function get_street(nf, ary, result, dirs, st_abbrevs,    f_st, i, street, l_street, ab, l_ab, ix, nf2, ary2, work) {

	# find the street part of the address
	f_st = 0
	if(nf == 1){	# minimum address is street, town
		result["status"] = "B"
		result["emsg"] = "no town"
		return 0
	}else{
		# street is the first field that matches one of these patterns
		for(i = 1; i < nf; i++){
			if(ary[i] ~ /^[1-9][0-9]* /){	# Simple number prefix
				f_st = i
				break
			}else if(ary[i] ~ /^[1-9][0-9]*-[1-9]/){	# Number range prefix
				f_st = i
				break
			}else if(ary[i] ~ /^[1-9][0-9]*[a-zA-Z] /){	# Number + 1 letter
				f_st = i
				break
			}
		}
		# ERROR: No street found
		if(f_st == 0){
			result["status"] = "B"
			result["emsg"] = "street?"
			return 0
		}
	}

	# ERROR: f_st is last field: no town
	if(f_st == nf){
		result["status"] = "B"
		result["emsg"] = "f_st=$"
		return 0
	}

	# replace str abbrev with their long forms
	street = ary[f_st]
	l_street = length(street)
	for(ab in st_abbrevs){
		l_ab = length(ab)
		if(l_ab > l_street)
			continue
		ix = l_street - l_ab + 1
		if(substr(street, ix) == ab){
			ary[f_st] = substr(street, 1, ix - 1) st_abbrevs[ab]
			break
		}
	}

	# replace single letter directions with their long forms
	nf2 = split(ary[f_st], ary2, /  */)
	work = ""
	for(i = 1; i <= nf2; i++){
		ary2[i] = ary2[i] in dirs ? dirs[ary2[i]] : ary2[i]
		work = work == "" ? ary2[i] : work " " ary2[i]
	}
	result["street"] = ary[f_st] = work
	return f_st
}
function get_town(nf, ary, result, f_st, st_quals, towns,   i, f_town) {

	# find the town:
	# 1. Set any street qualifiers (Apt 8, Bldg 2, etc) to ""
	# 2. The first field that is not "" is the town.
	for(i = f_st + 1; i <= nf; i++){
		ary[i] = rm_st_qual(ary[i], st_quals)
	}
	f_town = 0
	for(i = f_st + 1; i <= nf; i++){
		if(ary[i] != ""){
			f_town = i
			break
		}
	}
	if(f_town == 0){				# no town
		result["status"] = "B"
		result["emsg"  ] = "town?"
		return 0
	}

	# handle possible CA zip
	if(f_town == nf){				# town is last field, look closer
		if(ary[f_town] == "CA 94305"){		# Stanford is special
			ary[f_town] = "Stanford University"
		}else if(ary[f_town] ~ /^CA 9/){	# town cannot be a a zip code
			result["status"] = "B"
			result["emsg"  ] = "town=zip"
			return 0
		}
	}else if(f_town == nf - 1){			# town followed by 1 more field, look closer
		if(ary[nf] ~ /^CA [0-9]/){		# town followed by state zip, drop it
			ary[nf] = ""
		}else if(ary[nf] == "CA"){		# town followed by state, drop this field
			ary[nf] = ""
		}else{					# no idea
			result["status"] = "B"
			result["emsg"  ] = "town2?"
			return 0
		}
	}else{ 						# town followed by at least 2 fields, who knows?
		result["status"] = "B"
		result["emsg"  ] = "town3?"
		return 0
	}

	# Good to go
	# Replace abbreviated town w/full name
	ary[f_town] = (ary[f_town] in towns ? towns[ary[f_town]] : ary[f_town])
	result["town"] = ary[f_town]
	result["state"] = "CA"	# for now

	return f_town
}
function rm_st_qual(str, st_quals,   l_str, lc_str, u) {

	if(str ~ /^[#1-9]/)
		return ""
	l_str = length(str)
	lc_str = tolower(str)
	for(u in st_quals){
		l_u = length(u)
		if(l_str < l_u)
			continue
		if(substr(lc_str, 1, l_u) == u)
			return ""
        }
	return str
}
