function init_crange(crange, colorInfo,   nf, ary, nf2, ary2, R, G, B) {
	nf = split(crange, ary, ":")
	if(nf != 2){
		printf("ERROR: bad color range: %s, must be r,g,b:r,g,b r,g,b in [0,1]\n", crange) > "/dev/stderr"
		return 1
	}

	# get start color
	nf2 = split(ary[1], ary2, ",")
	if(nf2 != 3){
		printf("ERROR: bad start color: %s, must be r,g,b r,g,b in [0,1]\n", ary[1]) > "/dev/stderr"
		return 1
	}
	R = ary2[1]
	if(R < 0 || R > 1){
		printf("ERROR: bad start R value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[1]) > "/dev/stderr"
		return 1
	}
	G = ary2[2]
	if(G < 0 || G > 1){
		printf("ERROR: bad start G value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[2]) > "/dev/stderr"
		return 1
	}
	B = ary2[3]
	if(B < 0 || B > 1){
		printf("ERROR: bad start B value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[3]) > "/dev/stderr"
		return 1
	}
	colorInfo["R_start"] = R
	colorInfo["G_start"] = G
	colorInfo["B_start"] = B

	# get end color
	nf2 = split(ary[2], ary2, ",")
	if(nf2 != 3){
		printf("ERROR: bad end color: %s, must be r,g,b r,g,b in [0,1]\n", ary[2]) > "/dev/stderr"
		return 1
	}
	R = ary2[1]
	if(R < 0 || R > 1){
		printf("ERROR: bad end R value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[1]) > "/dev/stderr"
		return 1
	}
	G = ary2[2]
	if(G < 0 || G > 1){
		printf("ERROR: bad end G value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[2]) > "/dev/stderr"
		return 1
	}
	B = ary2[3]
	if(B < 0 || B > 1){
		printf("ERROR: bad end B value: %s, must be r,g,b r,g,b in [0,1]\n", ary2[3]) > "/dev/stderr"
		return 1
	}
	colorInfo["R_end"] = R
	colorInfo["G_end"] = G
	colorInfo["B_end"] = B

	return 0
}
function set_4bit_color(frac, colorInfo,    r_max_cval, R, G, B) {

	r_max_cval = 1.0/15
	R = int((frac * colorInfo["R_end"] + (1.0 - frac) * colorInfo["R_start"]) / r_max_cval)
	G = int((frac * colorInfo["G_end"] + (1.0 - frac) * colorInfo["G_start"]) / r_max_cval)
	B = int((frac * colorInfo["B_end"] + (1.0 - frac) * colorInfo["B_start"]) / r_max_cval)

	return sprintf("%x%x%x", R, G, B)
}
