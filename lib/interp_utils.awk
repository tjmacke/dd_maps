function IU_init(config, interp, name, k_values, k_breaks,   work, n_ary, ary, c_rng, i, nv) {

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
	for(i = 1; i <= n_ary; i++){
		work = ary[i]
		if(index(work, ":") != 0)
			c_rng++
		sub(/^[ \t]*/, "", work)
		sub(/[ \t]*$/, "", work)
		interp["values", i] = work
	}
	if(c_rng == 0)
		interp["is_grad"] = 0
	else if(c_rng == n_ary)
		interp["is_grad"] = 1
	else{
		printf("ERROR: IU_init: k_values can not include both gradient and bin values\n") > "/dev/stderr"
		return 1
	}

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
	if(interp["nbreaks"] != interp["nvalues"] - 1){
		printf("ERROR: IU_init: nbreaks (%d) != nvalues - 1 (%d)\n", interp["nbreaks"], interp["nvalues"] - 1) > "/dev/stderr"
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

function IU_interpolate(interp, v,   idx) {

	idx = IU_search(interp, v)
	interp["tcounts"]++
	if(!interp["is_grad"]){
		interp["counts", idx]++
		return interp["values", idx]
	}

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
