function IU_init(config, interp, name, k_values, k_breaks,    work, n_ary, ary, c_cnt, i, nv) {

	work = config["_globals", k_values]
	if(work == ""){
		printf("ERROR: no key named \"%s\" in config\n", k_values) > "/dev/stderr"
		return 1
	}
        interp["name"] = name
	nv = n_ary = split(work, ary, "|")
	interp["nvalues"] = n_ary
	c_cnt = 0
	for(i = 1; i <= n_ary; i++){
		work = ary[i]
		if(index(work, ":") != 0)	# continuous ranges have 2 values separated by a colon: start:end
			c_cnt++
		sub(/^[ \t]*/, "", work)
		sub(/[ \t]*$/, "", work)
		interp["values", i] = work
	}
	if(c_cnt == 0)
		interp["continuous"] = 0
	else if(c_cnt == n_ary)
		interp["continuous"] = 1
	else{
		printf("ERROR: mixed interpolator: %d continuous, %d discrete not allowed", c_cnt, n_ary - c_cnt) > "/dev/stderr"
		return 1
	}
	work = k_breaks != "" ? config["_globals", k_breaks] : ""
	if(work == ""){
		for(i = 1; i < nv; i++){
			interp["breaks", i] = i/(1.0*nv)
			interp["types", i] = "frac";
		}
	}else{
		n_ary = split(work, ary, "|")
		if(n_ary != nv - 1){
			printf("ERROR: wrong number of breaks %d, must be %d\n", n_ary, nv - 1) > "/dev/stderr"
			return 1
		}
		for(i = 1; i <= n_ary; i++){
			work = ary[i]
			sub(/^[ \t]*/, "", work)
			sub(/[ \t]*$/, "", work)
			interp["breaks", i] = work + 0	# force to number
			interp["types", i] = index(ary[i], ".") != 0 ? "frac" : "count"
		}
	}
	return 0
}

function IU_dump(file, interp,   i, keys, nk) {

	printf("interp = {\n") > file
	printf("\tname      = %s\n", interp["name"]) > file
	printf("\tcontinous = %d\n", interp["continuous"]) > file
	printf("\tnvalues   = %d\n", interp["nvalues"]) > file
	printf("\tvalues    = %s", interp["values", 1]) > file
	for(i = 2; i <= interp["nvalues"]; i++)
		printf(" | %s", interp["values", i]) > file
	printf("\n") > file
	printf("\tbreaks    = ") > file
	if(interp["nvalues"] == 1){
		printf("None")
	}else{
		printf("%s:%s", interp["breaks", 1], interp["types", 1]) > file
		for(i = 2; i <= interp["nvalues"] - 1; i++)
			printf(" | %s:%s", interp["breaks", i], interp["types", i]) > file
	}
	printf("\n") > file
	printf("}\n") > file
}

function IU_interpolate(interp, v, vmin, vmax,   v_idx, i, f, work, start, end, l_rvec, rvec, fb, bmin, bmax) {

	# all values are the same, return the first value
	if(vmin == vmax){
		if(interp["continuous"]){
			split(interp["values", 1], work, ":")
			return work[1]
		}else
			return interp["values", 1]
	}

	v_idx = interp["nvalues"]
	for(i = 1; i < interp["nvalues"]; i++){
		f = interp["types", i] == "count" ? v : (v - vmin)/(vmax - vmin)
		if(f <= interp["breaks", i]){
			v_idx = i
			break
		}
	}

	if(!interp["continuous"])
		return interp["values", v_idx]

	if(v_idx == 1){
		bmin = 0.0
		bmax = interp["breaks", v_idx]
	}else if(v_idx == interp["nvalues"]){
		bmin = interp["breaks", v_idx - 1]
		bmax = 1.0
	}else{
		bmax = interp["breaks", v_idx - 1]
		bmax = interp["breaks", v_idx]
	}
	fb = (f - bmin)/(bmax - bmin)

	split(interp["values", v_idx], work, ":")
	split(work[1], start, ",")
	l_rvec = split(work[2], end, ",")
	for(i = 1; i <= l_rvec; i++){
		rvec[i] = (1-fb) * start[i] + fb*end[i]
	}

	# TODO: fix this
	return sprintf("%g,%g,%g", rvec[1], rvec[2], rvec[3])
}
