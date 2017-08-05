function IU_init(config, interp, name, k_values, k_breaks,   work, n_ary, ary, c_rng, i, nv, v_pat) {

	interp["name"] = name

	# get the values
	work = config["_globals", k_values]
	if(work == ""){
		printf("ERROR: IU_init: no key named \"%s\" in config\n", k_values) > "/dev/stderr"
		return 1
	}
	nv = n_ary = split(work, ary, "|")
	interp["nvalues"] = n_ary
	c_rng = 0
	v_ob_info = ""
	for(i = 1; i <= n_ary; i++){
		work = ary[i]
		if(index(work, ":") != 0){
			c_rng++
			v_pat = v_pat "g"
		}else
			v_pat = v_pat "b"
		sub(/^[ \t]*/, "", work)
		sub(/[ \t]*$/, "", work)
		interp["values", i] = work
	}
	interp["is_grad"] = c_rng > 0

	# get the breaks
	work = config["_globals", k_breaks]
	if(work == ""){
		printf("ERROR: IU_init: no key named \"%s\" in config\n", k_values) > "/dev/stderr"
		return 1
	}
	nv = n_ary = split(work, ary, "|")
	interp["nbreaks"] = n_ary
	for(i = 1; i <= n_ary; i++){
		work = ary[i]
		sub(/^[ \t]*/, "", work)
		sub(/[ \t]*$/, "", work)
		interp["breaks", i] = work + 0	# force numeric
	}
	if(!interp["is_grad"]){
		if(interp["nbreaks"] != interp["nvalues"] - 1){
			printf("ERROR: IU_init: nbreaks (%d) != nvalues - 1 (%d)\n", interp["nbreaks"], interp["nvalues"] - 1) > "/dev/stderr"
			return 1
		}
	}else if(interp["nbreaks"] == interp["nvalues"] + 1){
		if(!match(v_pat, /^gg*$/)){
			printf("ERROR: IU_init: nbreaks (%d) = nvalues + 1 (%d): all values must be gradients\n", interp["nbreaks"], interp["nvalues"] + 1) > "/dev/stderr"
			return 1
		}
		interp["v_ob_info"] = ""
	}else if(interp["nbreaks"] == interp["nvalues"]){
		if(!match(v_pat, /^bgg*$/) && !match(v_pat, /^gg*b$/)){
			printf("ERROR: IU_init: nbreaks (%d) = nvalues (%d): All but first or last, but not both  values must grad\n", inter["nbreaks"], interp["nvalues"]) > "/dev/stderr"
			return 1
		}
		interp["v_ob_info"] = v_pat ~ /^b/ ? "^" : "$"
	}else if(interp["nbreaks"] = interp["nvalues"] - 1){
		printf("DEBUG: IU_init: nb = nv - 1: chk that we have v[1] = bin, v[2:$-1] = grad, v[$] = bin\n") > "/dev/stderr"
		if(!match(v_pat, /^bgg*b$/)){
			printf("ERROR: IU_init: nbreaks (%d) = nvalues - 1 (%d): all values but first and last must be gread\n", interp["nbreaks"], interp["nvalues"] - 1) > "/dev/stderr"
			return 1
		}
		interp["v_ob_info"] = "^$"
	}else{
		printf("ERROR: IU_init: nbreaks (%d) != nvalues +/- 1 (%d, %d, %d)\n", interp["nbreaks"], interp["nvalues"] - 1, interp["nvalues"], interp["nvalues"] + 1) > "/dev/stderr"
		return 1
	}

	# init all counts to 0
	for(i = 0; i <= interp["nbreaks"] + 1; i++)
		interp["counts", i] = 0
	interp["tcounts"] = 0

	return 0
}

function IU_dump(file, interp,   i, keys, nk) {

	printf("interp = {\n") > file
	printf("\tname          = %s\n", interp["name"]) > file
	printf("\tis_grad       = %d\n", interp["is_grad"]) > file
	printf("\tv_ob_info     = %s\n", interp["v_ob_info"]) > file
	printf("\tnvalues       = %d\n", interp["nvalues"]) > file
	printf("\tvalues        = %s", interp["values", 1]) > file
	for(i = 2; i <= interp["nvalues"]; i++)
		printf(" | %s", interp["values", i]) > file
	printf("\n") > file
	printf("\tnbreaks       = %d\n", interp["nbreaks"]) > file
	printf("\tbreaks        = %s", interp["breaks", 1]) > file
	for(i = 2; i <= interp["nbreaks"]; i++)
		printf(" | %s", interp["breaks", i]) > file
	printf("\n") > file
	printf("\ttcounts       = %d\n", interp["tcounts"]) > file
	printf("\tcounts        = %d", interp["counts", 1]) > file
	for(i = 2; i <= interp["nbreaks"] + 1; i++)
		printf(" | %d", interp["counts", i]) > file
	printf("\n") > file
	printf("}\n") > file
}

function IU_interpolate(interp, v,   idx, work, n_ary, ary, i) {

	idx = IU_search(interp, v)
	interp["tcounts"]++
	interp["counts", idx]++
	if(!interp["is_grad"]){
		return interp["values", idx]
	}else{
		# nbreaks = nvalues - 1
		if(interp["v_ob_info"]  == ""){	# ^gg*$, take out of bounds values from first and last grad elemnt
			if(idx == 1){
				work = interp["values", 1]
				n_ary = split(work, ary, ":")
				return ary[1]
			}else if(idx == interp["nbreaks"] + 1){
				work = interp["values", interp["nvalues"]]
				n_ary = split(work, ary, ":")
				return ary[2]
			}else{	
				# TODO: do the actual interpolation
				IU_interpolate_vec(interp["values", idx - 1], v, interp["breaks", idx - 1], interp["breaks", idx])
				return interp["values", idx - 1]
			}
		}else if(interp["v_ob_info"] == "^"){	# ^bgg*$, lower out of bounds specified, take higher ob from last grad element
			if(idx == 1)
				return interp["values", 1]
			else if(idx == interp["nbreaks"] + 1){
				work = interp["values", interp["nvalues"]]
				n_ary = split(work, ary, ":")
				return ary[2]
			}else{
				# TODO: do the actual interpolation
				return interp["values", idx]
			}
		}else if(interp["v_ob_info"] == "$"){	# ^gg*b$, upper out of bounds specified, take lower ob from first grad element
			if(idx == 1){
				work = interp["values", 1]
				n_ary = split(work, ary, ":")
				return ary[1]
			}else if(idx == interp["nbreaks"] + 1){ 
				return interp["values", idx - 1]
			}else{
				# TODO: do the actual interpolation
				return interp["values", idx - 1]
			}
		}else{	# ^bgg*b$, lower & upper ob info specified
			if(idx == 1 || idx == interp["nbreaks"] + 1)
				return interp["values", idx]
			else{
				# TODO: do the actual interpolation
				return interp["values", idx]
			}
		}
		return v_type
	}
}

function IU_interpolate_vec(vec, v, v_min, v_max) {

	printf("DEBUG: IU_interpolate_vec: vec = %s, v = %g, v_min = %g, v_max = %g\n", vec, v, v_min, v_max)
	return ""
}

function IU_search(interp, v,   i, j, k, cv) {

	# deal with out of range values here to simplify the binary interval search
	if(v <= interp["breaks", 1])
		return 1
	else if(v > interp["breaks", interp["nbreaks"]])
		return interp["nbreaks"] + 1

	# binary search on intervals
	i = 1 ; j = interp["nbreaks"];
	for( ; i <= j ; ){
		k = int((i+j)/2)
		if(v == interp["breaks", k]){
			return k
		}else if(v < interp["breaks", k]){
			if(v > interp["breaks", k-1])
				return k
			j = k - 1
		}else{
			if(v <= interp["breaks", k+1])
				return k + 1
			i = k + 1
		}
	}
	# should never get here!
	return 0
}
