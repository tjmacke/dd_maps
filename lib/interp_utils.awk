function IU_init(config, interp, name, k_values, k_breaks,   work, n_ary, ary, i, nv, v_pat, v_len) {

	interp["name"] = name

	# get the values
	work = config["_globals", k_values]
	if(work == ""){
		printf("ERROR: IU_init: no key named \"%s\" in config\n", k_values) > "/dev/stderr"
		return 1
	}
	nv = n_ary = split(work, ary, "|")
	interp["nvalues"] = n_ary
	interp["is_grad"] = 0
	interp["v_len"] = 0	# set only for grad elts
	for(i = 1; i <= n_ary; i++){
		sub(/^[ \t]*/, "", ary[i])
		sub(/[ \t]*$/, "", ary[i])
		if(index(ary[i], ":") != 0){
			interp["is_grad"] = 1
			v_pat = v_pat "g"
			v_len = IU_check_grad(ary[i])
			if(v_len == 0){
				printf("ERROR: IU_init: IU_check_grad failed for value %d (%s)\n", i, ary[i]) > "/dev/stderr"
				return 1
			}else if(interp["v_len"] == 0){
				interp["v_len"] = v_len
			}else if(v_len != interp["v_len"]){
				printf("ERROR: IU_init: v_len (%d) for value %d (%s) differs from current v_len (%d)\n", v_len, i, ary[i], interp["v_len"]) > "/dev/stderr"
				return 1
			}
		}else
			v_pat = v_pat "b"
		interp["values", i] = ary[i]
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
		sub(/^[ \t]*/, "", ary[i])
		sub(/[ \t]*$/, "", ary[i])
		interp["breaks", i] = ary[i] + 0	# force numeric
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
			printf("ERROR: IU_init: nbreaks (%d) = nvalues (%d): All but first or last, but not both values must grad\n", interp["nbreaks"], interp["nvalues"]) > "/dev/stderr"
			return 1
		}
		interp["v_ob_info"] = v_pat ~ /^b/ ? "^" : "$"
	}else if(interp["nbreaks"] = interp["nvalues"] - 1){
		printf("DEBUG: IU_init: nb = nv - 1: chk that we have v[1] = bin, v[2:$-1] = grad, v[$] = bin\n") > "/dev/stderr"
		if(!match(v_pat, /^bgg*b$/)){
			printf("ERROR: IU_init: nbreaks (%d) = nvalues - 1 (%d): all values but first and last must be grad\n", interp["nbreaks"], interp["nvalues"] - 1) > "/dev/stderr"
			return 1
		}
		interp["v_ob_info"] = "^$"
	}else{
		printf("ERROR: IU_init: nbreaks (%d) != nvalues +/- 1 (%d, %d, %d)\n", interp["nbreaks"], interp["nvalues"] - 1, interp["nvalues"], interp["nvalues"] + 1) > "/dev/stderr"
		return 1
	}

	# check that breaks are strictly ascending, insures interp denoms are > 0
	for(i = 2; i <= interp["nbreaks"]; i++){
		if(interp["breaks", i] <= interp["breaks", i-1]){
			printf("ERROR: IU_init: breaks must be strictly ascending: breaks[%d] (%g) <= breaks[%d] (%g)\n", i-1, interp["breaks", i-1], i, interp["breaks", i]) > "/dev/stderr"
			return 1
		}
	}

	# init all counts to 0
	for(i = 0; i <= interp["nbreaks"] + 1; i++)
		interp["counts", i] = 0
	interp["tcounts"] = 0

	return 0
}

function IU_check_grad(grad,   v_len, n_ary, ary, i, n_ary2, ary2, j) {

	v_len = 0
	n_ary = split(grad, ary, ":")
	if(n_ary != 2){
		printf("ERROR: IU_check_grad: grad %s has %d fields, must have %d\n", grad, n_ary, 2) > "/dev/stderr"
		return 0
	}
	for(i = 1; i <= n_ary; i++){
		n_ary2 = split(ary[i], ary2, ",")
		if(v_len == 0)
			v_len = n_ary2
		else if(n_ary2 != v_len){
			printf("ERROR: IU_check_grad: vector %s has %d elements, must have %d\n", ary[i], n_ary2, v_len) > "/dev/stderr"
			return 0
		}
	}

	return v_len
}

function IU_dump(file, interp,   i, keys, nk) {

	printf("interp = {\n") > file
	printf("\tname          = %s\n", interp["name"]) > file
	printf("\tis_grad       = %d\n", interp["is_grad"]) > file
	printf("\tv_ob_info     = %s\n", interp["v_ob_info"]) > file
	printf("\tv_len         = %d\n", interp["v_len"]) > file
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
			}else	
				return IU_interpolate_grad(interp["values", idx - 1], v, interp["breaks", idx - 1], interp["breaks", idx])
		}else if(interp["v_ob_info"] == "^"){	# ^bgg*$, lower out of bounds specified, take higher ob from last grad element
			if(idx == 1)
				return interp["values", 1]
			else if(idx == interp["nbreaks"] + 1){
				work = interp["values", interp["nvalues"]]
				n_ary = split(work, ary, ":")
				return ary[2]
			}else
				return IU_interpolate_grad(interp["values", idx], v, interp["breaks", idx], interp["breaks", idx + 1])
		}else if(interp["v_ob_info"] == "$"){	# ^gg*b$, upper out of bounds specified, take lower ob from first grad element
			if(idx == 1){
				work = interp["values", 1]
				n_ary = split(work, ary, ":")
				return ary[1]
			}else if(idx == interp["nbreaks"] + 1)
				return interp["values", idx - 1]
			else
				return IU_interpolate_grad(interp["values", idx - 1], v, interp["breaks", idx - 1], interp["breaks", idx])
		}else{	# ^bgg*b$, lower & upper ob info specified
			if(idx == 1 || idx == interp["nbreaks"] + 1)
				return interp["values", idx]
			else
				return IU_interpolate_grad(interp["values", idx], v, interp["breaks", idx], interp["breaks", idx + 1])
		}
		return v_type
	}
}

function IU_interpolate_grad(grad, v, v_min, v_max,   n_ary, ary, n_ary2, ary2, i, g_min, g_max, f, rstr) {

	# grad is well formed or IU_init() would have failed
	n_ary = split(grad, ary, ":")
	n_ary2 = split(ary[1], ary2, ",")
	for(i = 1; i <= n_ary2; i++)
		g_min[i] = ary2[i] + 0	# force numeric
	n_ary2 = split(ary[2], ary2, ",")
	for(i = 1; i <= n_ary2; i++)
		g_max[i] = ary2[i] + 0	# force numeric
	f = (v - v_min) / (v_max - v_min)	# safe b/c IU_init() checked that v_max > v_min
	rstr = ""
	for(i = 1; i <= n_ary2; i++){
		rstr = rstr ((i > 1) ? "," : "") sprintf("%g", g_min[i] + f * (g_max[i] - g_min[i]))
	}
	return rstr
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
