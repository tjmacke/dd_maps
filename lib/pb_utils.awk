function read_pay_breakdown(pb_file, pb_keys, pb_vals, pb_fields, pb_sizes,   n_pb_lines, line, nf, ary, f) {

	pb_sizes["n_pb_keys"] = 0
	pb_sizes["n_pb_fields"] = 0

	for(n_pb_lines = 0; (getline line < pb_file) > 0; ){
		n_pb_lines++
		nf = split(line, ary, "\t")
		if(n_pb_lines == 1){
			pb_sizes["n_pb_fields"] = nf
			for(f = 1; f <= nf; f++)
				pb_fields[ary[f]] = f
		}
		pb_keys[n_pb_lines - 1] = ary[1]
		pb_vals[n_pb_lines - 1] = line
	}
	pb_sizes["n_pb_keys"] = n_pb_lines - 1
	close(pb_file)

	return n_pb_lines - 1
}
function find_pay_data(key, n_ktab, ktab, k_idx,   i, j, k, k1) {

	k_idx["start"] = -1
	k_idx["end"]   = -1

	i = 1 ; j = n_ktab
	for( ; i <= j; ){
		k = int((i + j)/2)
		if(ktab[k] < key){
			i = k + 1
		}else if(ktab[k] > key){
			j = k - 1
		}else{
			# keys can have > 1 value
			for(k1 = k; k1 - 1 >= 1; ){
				if(ktab[k1 - 1] != key)
					break;
				k1--
			}
			k_idx["start"] = k1

			for(k1 = k; k1 + 1 <= n_ktab; ){
				if(ktab[k1 + 1] != key)
					break
				k1++
			}
			k_idx["end"]   = k1

			return 1
		}
	}
	return 0
}
function pb_dashes_overlap(b_dash1, e_dash1, b_dash2, e_dash2,   b_min1, e_min1, b_min2, e_min2) {

	b1_min = 60 * substr(b_dash1, 1, 2) + substr(b_dash1, 3, 2)
	e1_min = 60 * substr(e_dash1, 1, 2) + substr(e_dash1, 3, 2)

	b2_min = 60 * substr(b_dash2, 1, 2) + substr(b_dash2, 3, 2)
	e2_min = 60 * substr(e_dash2, 1, 2) + substr(e_dash2, 3, 2)

	if(e1_min <= b2_min)
		return 0
	else if(e2_min <= b1_min)
		return 0
	else
		return 1
}
