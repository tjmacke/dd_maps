function read_addresses(afile, a2idx, acnt, along, alat,   n_a2idx, aline, nf, ary) {
	for(n_a2idx = 0; (getline aline < afile) > 0; ){
		nf = split(aline, ary, "\t")
		n_a2idx++
		a2idx[ary[2]] = n_a2idx
		acnt[n_a2idx] = ary[1]
		along[n_a2idx] = ary[3]
		alat[n_a2idx] = ary[4]
		
	}
	close(afile)
	return n_a2idx
}
