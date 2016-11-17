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
function pb_dash_in_shift(b_dash, e_dash, b_shift, e_shift,   bd_min, ed_min, bs_min, es_min) {

	bd_min = 60 * substr(b_dash, 1, 2) + substr(b_dash, 3, 2)
	ed_min = 60 * substr(e_dash, 1, 2) + substr(e_dash, 3, 2)

	bs_min = 60 * substr(b_shift, 1, 2) + substr(b_shift, 3, 2)
	es_min = 60 * substr(e_shift, 1, 2) + substr(e_shift, 3, 2)

	return bd_min >= bs_min && ed_min <= es_min
}
