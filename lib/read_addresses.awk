function read_addresses(afile, a2idx, alng, alat,   n_a2idx, aline, nf, ary) {
	for(n_a2idx = 0; (getline aline < afile) > 0; ){
		nf = split(aline, ary, "\t")
		n_a2idx++
		a2idx[ary[1]] = n_a2idx
		alng[n_a2idx] = ary[2]
		alat[n_a2idx] = ary[3]
		
	}
	close(afile)
	return n_a2idx
}
