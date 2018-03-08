function IU_init(config, interp, name,    key, work, n_ary, ary, i, v_pat, parms) {

	interp["name"] = name

	# get the scale type linear (default), log10 and factor so far
	key = name ".scale_type"
	work = config["_globals", key]
	if(work == "")
		interp["scale_type"] = "linear"
	else if(work == "linear" || work == "log" || work == "factor")
		interp["scale_type"] = work
	else{
		print("ERROR: IU_init: unknown scale_type: %s\n", key) > "/dev/stderr"
		return 1
	}

	# get the values
	key = name ".values"
	work = config["_globals", key]
	if(work == ""){
		printf("ERROR: IU_init: no key named \"%s\" in config\n", key) > "/dev/stderr"
		return 1
	}
	n_ary = split(work, ary, "|")
	interp["nvalues"] = n_ary
	interp["is_grad"] = 0
	interp["v_len"] = 0	# set only for grad elts
	for(i = 1; i <= n_ary; i++){
		sub(/^[ \t]*/, "", ary[i])
		sub(/[ \t]*$/, "", ary[i])
		parms["grad"] = ary[i]
		if(index(ary[i], ":") != 0){
			interp["is_grad"] = 1
			v_pat = v_pat "g"
			parms["v_len"] = 0
			if(_IU_check_grad(config, parms)){
				printf("ERROR: IU_init: _IU_check_grad failed for value %d (%s)\n", i, ary[i]) > "/dev/stderr"
				return 1
			}else if(interp["v_len"] == 0){
				interp["v_len"] = parms["v_len"]
			}else if(parms["v_len"] != interp["v_len"]){
				printf("ERROR: IU_init: v_len (%d) for value %d (%s) differs from current v_len (%d)\n", parms["v_len"], i, ary[i], interp["v_len"]) > "/dev/stderr"
				return 1
			}
		}else{
			if(substr(ary[i], 1, 1) == "$"){
				work = config["_globals", substr(ary[i], 2)]
				if(work == ""){
					printf("ERROR: IU_init: macro %s not defined\n", ary[i]) > "/dev/stderr"
					return 1
				}else
					parms["grad"] = work
			}
			v_pat = v_pat "b"
		}
		interp["values", i] = parms["grad"]
	}

	# get the breaks for log/linear or keys for factor
	if(interp["scale_type"] == "linear" || interp["scale_type"] == "log"){
		key = name ".breaks"
		work = config["_globals", key]
		if(work == ""){
			printf("ERROR: IU_init: no key named \"%s\" in config\n", key) > "/dev/stderr"
			return 1
		}
		n_ary = split(work, ary, "|")
		interp["nbreaks"] = n_ary
		for(i = 1; i <= n_ary; i++){
			sub(/^[ \t]*/, "", ary[i])
			sub(/[ \t]*$/, "", ary[i])
			interp["breaks", i] = ary[i] + 0	# force numeric
		}
	}else{
		key = name ".keys"
		work = config["_globals", key]
		if(work == ""){
			printf("ERROR: IU_init: no key named \"%s\" in config\n", key) > "/dev/stderr"
			return 1
		}
		n_ary = split(work, ary, "|")
		interp["nkeys"] = n_ary
		for(i = 1; i <= n_ary; i++){
			sub(/^[ \t]*/, "", ary[i])
			sub(/[ \t]*$/, "", ary[i])
			interp["k2v", ary[i]] = interp["values", i]	# leave as string
			interp["keys", i] = ary[i]
		}
		# get the default color for values do not match any key
		key = name ".def_value"
		work = config["_globals", key]
		if(work == ""){
			printf("ERROR: IU_init: no key named \"%s\" in config\n", key) > "/dev/stderr"
			return 1
		}else if(substr(work, 1, 1) == "$"){
			work = config["_globals", substr(work, 2)]
			if(work == ""){
				printf("ERROR: IU_init: macro $%s not defined\n", work) > "/dev/stderr"
				return 1
			}
		}
		interp["def_value"] = work
		key = name ".def_key_text"
		work = config["_globals", key]
		if(work == ""){
			printf("ERROR: IU_init: no key named \"%s\" in config\n", key) > "/dev/stderr"
			return 1
		}else if(substr(work, 1, 1) == "$"){
			work = config["_globals", substr(work, 2)]
			if(work == ""){
				printf("ERROR: IU_init: macro $%s not defined\n", work) > "/dev/stderr"
				return 1
			}
		}
		interp["def_key_text"] = work
	}
	if(interp["scale_type"] == "factor"){
		if(interp["nkeys"] != interp["nvalues"]){
			printf("ERROR: IU_init: nkeys (%d) != nvalues (%d)\n", interp["nkeys"], interp["nvalues"]) > "/dev/stderr"
			return 1
		}
	}else if(!interp["is_grad"]){
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
	}else if(interp["nbreaks"] == interp["nvalues"] - 1){
		if(!match(v_pat, /^bgg*b$/)){
			printf("ERROR: IU_init: nbreaks (%d) = nvalues - 1 (%d): all values but first and last must be grad\n", interp["nbreaks"], interp["nvalues"] - 1) > "/dev/stderr"
			return 1
		}
		interp["v_ob_info"] = "^$"
	}else{
		printf("ERROR: IU_init: bad nbreaks (%d), legal values are (%d, %d, %d)\n", interp["nbreaks"], interp["nvalues"] - 1, interp["nvalues"], interp["nvalues"] + 1) > "/dev/stderr"
		return 1
	}

	interp["tcounts"] = 0
	if(interp["scale_type"] == "factor"){
		# init all counts to 0
		for(i = 0; i <= interp["nkeys"] + 1; i++)
			interp["counts", interp["keys", i]] = 0
		interp["counts", interp["def_value"]] = 0
	}else{
		# check that breaks are strictly ascending, insures interp denoms are > 0
		for(i = 2; i <= interp["nbreaks"]; i++){
			if(interp["breaks", i] <= interp["breaks", i-1]){
				printf("ERROR: IU_init: breaks must be strictly ascending: breaks[%d] (%g) <= breaks[%d] (%g)\n", i-1, interp["breaks", i-1], i, interp["breaks", i]) > "/dev/stderr"
				return 1
			}
		}

		# check for any exceptions
		key = name ".exceptions"
		work = config["_globals", key]
		if(work != ""){
			if(_IU_parse_exceptions(config, interp, work))
				return 1
		}

		# init all counts to 0
		for(i = 0; i <= interp["nbreaks"] + 1; i++)
			interp["counts", i] = 0
	}

	return 0
}

function IU_interpolate(interp, v,   vn, ev, idx, work, n_ary, ary, i) {

	# handle factors first and then return
	if(interp["scale_type"] == "factor"){
		ev = interp["k2v", v]
		if(ev == "")
			ev = interp["def_value"]
		interp["tcounts"]++
		interp["counts", ev]++
		return ev
	}

	# numeric interpolation
	vn = v + 0	# force number
	if("exceptions" in interp){
		ev = _IU_handle_exceptions(interp, vn)
		if(ev != "")
			return ev
	}else if(interp["scale_type"] == "log"){
		if(vn <= 0)
			return ""
	}

	idx = _IU_search(interp, vn)
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
				return _IU_interpolate_grad(interp, interp["values", idx - 1], vn, interp["breaks", idx - 1], interp["breaks", idx])
		}else if(interp["v_ob_info"] == "^"){	# ^bgg*$, lower out of bounds specified, take higher ob from last grad element
			if(idx == 1)
				return interp["values", 1]
			else if(idx == interp["nbreaks"] + 1){
				work = interp["values", interp["nvalues"]]
				n_ary = split(work, ary, ":")
				return ary[2]
			}else
				return _IU_interpolate_grad(interp, interp["values", idx], vn, interp["breaks", idx], interp["breaks", idx + 1])
		}else if(interp["v_ob_info"] == "$"){	# ^gg*b$, upper out of bounds specified, take lower ob from first grad element
			if(idx == 1){
				work = interp["values", 1]
				n_ary = split(work, ary, ":")
				return ary[1]
			}else if(idx == interp["nbreaks"] + 1)
				return interp["values", idx - 1]
			else
				return _IU_interpolate_grad(interp, interp["values", idx - 1], vn, interp["breaks", idx - 1], interp["breaks", idx])
		}else{	# ^bgg*b$, lower & upper ob info specified
			if(idx == 1 || idx == interp["nbreaks"] + 1)
				return interp["values", idx]
			else
				return _IU_interpolate_grad(interp, interp["values", idx], vn, interp["breaks", idx], interp["breaks", idx + 1])
		}
	}
}

function IU_dump(file, interp,   i, keys, nk) {

	printf("interp = {\n") > file
	printf("\tname          = %s\n", interp["name"]) > file
	printf("\tscale_type    = %s\n", interp["scale_type"]) > file
	if(interp["scale_type"] != "factor"){
		printf("\tis_grad       = %d\n", interp["is_grad"]) > file
		printf("\tv_ob_info     = %s\n", interp["v_ob_info"]) > file
		printf("\tv_len         = %d\n", interp["v_len"]) > file
	}
	printf("\tnvalues       = %d\n", interp["nvalues"]) > file
	printf("\tvalues        = %s", interp["values", 1]) > file
	for(i = 2; i <= interp["nvalues"]; i++)
		printf(" | %s", interp["values", i]) > file
	printf("\n") > file
	if(interp["scale_type"] == "factor"){
		printf("\tnkeys         = %d\n", interp["nkeys"]) > file
		printf("\tkeys          = %s", interp["keys", 1]) > file
		for(i = 2; i <= interp["nkeys"]; i++)
			printf(" | %s", interp["keys", i]) > file
		printf("\n") > file
		printf("\tdef_value     = %s\n", interp["def_value"]) > file
		printf("\tdef_key_text  = %s\n", interp["def_key_text"]) > file
		printf("\ttcounts       = %d\n", interp["tcounts"]) > file
		printf("\tcounts        = %d", interp["counts", interp["keys", 1]]) > file
		for(i = 2; i <= interp["nkeys"] + 1; i++)
			printf(" | %d", interp["counts", interp["keys", i]]) > file
		printf(" | %d", interp["counts", interp["def_value"]]) > file
		printf("\n") > file
	}else{
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
		if(!("exceptions" in interp))
			printf("\texceptions    =\n") > file
		else{
			printf("\texceptions    = %d {\n", interp["nexceptions"]) > file
			for(i = 1; i <= interp["nexceptions"]; i++)
				printf("\t\t%d = %s | %s | %s\n", i, interp["exceptions", i, "op"], interp["exceptions", i, "opnd"], interp["exceptions", i, "value"]) > file
			printf("\t}\n") > file
			printf("\tecounts       = %d", interp["ecounts", 1]) > file
			for(i = 2; i <= interp["nexceptions"]; i++)
				printf(" | %d", interp["ecounts", i]) > file
			printf("\n") > file
		}
	}
	printf("}\n") > file
}

function _IU_check_grad(config, parms,    v_len, n_ary, ary, i, work, n_ary2, ary2, j, xgrad, xval) {

	parms["v_len"] = 0
	n_ary = split(parms["grad"], ary, ":")
	if(n_ary != 2){
		printf("ERROR: _IU_check_grad: grad %s has %d fields, must have %d\n", grad, n_ary, 2) > "/dev/stderr"
		return 1
	}
	xgrad = ""
	for(i = 1; i <= n_ary; i++){
		n_ary2 = split(ary[i], ary2, ",")
		if(parms["v_len"] == 0)
			parms["v_len"] = n_ary2
		else if(n_ary2 != parms["v_len"]){
			printf("ERROR: _IU_check_grad: vector %s has %d elements, must have %d\n", ary[i], n_ary2, parms["v_len"]) > "/dev/stderr"
			return 1
		}
		if(substr(ary[i], 1, 1) == "$"){
			xval = config["_globals", substr(ary[i], 2)]
			if(xval == ""){
				printf("ERROR: _IU_check_grad: macro %s is not defined\n", ary[i]) > "/dev/stderr"
				return 1
			}
		}else
			xval = ary[i]
		xgrad = xgrad (i > 1 ? ":" : "") xval
	}
	parms["grad"] = xgrad

	return 0
}

function _IU_parse_exceptions(config, interp, str,   err, n_ary, ary, i, work, colon, cond, op, opnd, value, xvalue) {

	err = 0
	interp["exceptions"] = str
	n_ary = split(str, ary, "|")
	for(i = 1; i <= n_ary; i++){
		sub(/^  */, "", ary[i])
		sub(/  *$/, "", ary[i])
	}
	interp["nexceptions"] = n_ary
	for(i = 1; i <= n_ary; i++){
		colon = index(ary[i], ":")
		if(colon == 0){
			printf("ERROR: _IU_parse_exception: no colon: %s\n", ary[i]) > "/dev/stderr"
			return 1
		}
		cond = substr(ary[i], 1, colon - 1)
		sub(/^  */, "", cond)
		sub(/  *$/, "", cond)
		if(cond == ""){
			printf("ERROR: _IU_parse_exception: empty condition: %s\n", ary[i]) > "/dev/stderr"
			return 1
		}
		# op can be <=, <, ==, !=, >=, >
		op = substr(cond, 1, 2)
		if(op == "<=" || op == "==" || op == "!=" || op == ">="){
			opnd = substr(cond, 3)
		}else{
			op = substr(op, 1, 1)
			if(op == "<" || op == ">")
				opnd = substr(cond, 2)
			else{
				printf("ERROR: _IU_parse_exception: unknown operator \"%s\"\n", cond) > "/dev/stderr"
				return 1
			}
		}
		sub(/^  */, "", opnd)
		sub(/  *$/, "", opnd)
		if(cond == ""){
			print("ERROR: _IU_parse_exception: exception %d: %s: empty operand\n", i, ary[i]) > "/dev/stderr"
			return 1
		}

		value = substr(ary[i], colon + 1)
		sub(/^  */, "", value)
		sub(/  *$/, "", value)
		# TODO? value can be empty, is this OK?
		if(value == ""){
			printf("ERROR: _IU_parse_exception: exception %d: %s: empty value\n", i, ary[i]) > "/dev/stderr"
			return 1
		}else if(substr(value, 1, 1) == "$"){
			xvalue = config["_globals", substr(value, 2)]
			if(xvalue == ""){
				printf("ERROR: _IU_parse_exception: macro %s is not defined\n", value) > "/dev/stderr"
				return 1
			}
			value = xvalue
		}

		interp["exceptions", i, "op"] = op 
		interp["exceptions", i, "opnd"] = opnd + 0 # force numeric
		interp["exceptions", i, "value"] = value
		interp["ecounts", i] = 0
	}
	return err
}

function _IU_handle_exceptions(interp, v,   i, hit) {

	for(i = 1; i <= interp["nexceptions"]; i++){
		hit = ""
		if(interp["exceptions", i, "op"] == "<"){
			if(v < interp["exceptions", i, "opnd"])
				hit = "<"
		}else if(interp["exceptions", i, "op"] == "<="){
			if(v <= interp["exceptions", i, "opnd"])
				hit = "<="
		}else if(interp["exceptions", i, "op"] == "=="){
			if(v == interp["exceptions", i, "opnd"])
				hit = "=="
		}else if(interp["exceptions", i, "op"] == "!="){
			if(v != interp["exceptions", i, "opnd"])
				hit = "!="
		}else if(interp["exceptions", i, "op"] == ">="){
			if(v >= interp["exceptions", i, "opnd"])
				hit = ">="
		}else if(v >= interp["exceptions", i, "opnd"])
			hit = ">"
		if(hit){
			interp["ecounts", i]++
			interp["tcounts"]++
			return interp["exceptions", i, "value"]
		}
	}

	return ""
}

function _IU_search(interp, v,   i, j, k, cv) {

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

function _IU_interpolate_grad(interp, grad, v, v_min, v_max,   n_ary, ary, n_ary2, ary2, i, g_min, g_max, f, rstr) {

	# grad is well formed or IU_init() would have failed
	n_ary = split(grad, ary, ":")
	n_ary2 = split(ary[1], ary2, ",")
	for(i = 1; i <= n_ary2; i++)
		g_min[i] = ary2[i] + 0	# force numeric
	n_ary2 = split(ary[2], ary2, ",")
	for(i = 1; i <= n_ary2; i++)
		g_max[i] = ary2[i] + 0	# force numeric

	# other scales may be possible but for now
	if(interp["scale_type"] == "log"){
		log10 = log(10)
		v = log(v)/log10
		v_min = log(v_min)/log10
		v_max = log(v_max)/log10
	}

	f = (v - v_min) / (v_max - v_min)	# safe b/c IU_init() checked that v_max > v_min
	rstr = ""
	for(i = 1; i <= n_ary2; i++){
		rstr = rstr ((i > 1) ? "," : "") sprintf("%g", g_min[i] + f * (g_max[i] - g_min[i]))
	}
	return rstr
}
