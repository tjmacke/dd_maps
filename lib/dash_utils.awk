function DU_read_dashes(dfile, dash_keys, dash_vals, dash_fields, dash_sizes,   n_dash_lines, line, nf, ary, f) {

	dash_sizes["n_dash_keys"] = 0
	dash_sizes["n_dash_fields"] = 0

	for(n_dash_lines = 0; (getline line < dfile) > 0; ){
		n_dash_lines++
		nf = split(line, ary, "\t")
		if(n_dash_lines == 1){
			dash_sizes["n_dash_fields"] = nf
			for(f = 1; f <= nf; f++)
				dash_fields[ary[f]] = f
		}
		dash_keys[n_dash_lines - 1] = ary[1]
		dash_vals[n_dash_lines - 1] = line
	}
	dash_sizes["n_dash_keys"] = n_dash_lines - 1
	close(dfile)

	return n_dash_lines - 1
}
function DU_find_dash_cands(key, n_ktab, ktab, k_idx,   i, j, k, k1) {

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
function DU_job_in_dash(b_job, e_job, b_dash, e_dash,   bj_min, ej_min, bd_min, ed_min) {

	bj_min = 60 * substr(b_job, 1, 2) + substr(b_job, 3, 2)
	ej_min = 60 * substr(e_job, 1, 2) + substr(e_job, 3, 2)

	bd_min = 60 * substr(b_dash, 1, 2) + substr(b_dash, 3, 2)
	ed_min = 60 * substr(e_dash, 1, 2) + substr(e_dash, 3, 2)

	return bj_min >= bd_min && ej_min <= ed_min
}
