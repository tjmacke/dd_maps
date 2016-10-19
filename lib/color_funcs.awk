function init_crange(crange, colorInfo,   nf, ary, nf2, ary2, R, G, B, rgb, hsv) {

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
	rgb["R"] = R
	rgb["G"] = G
	rgb["B"] = B
	rgb2hsv(rgb, hsv)

	colorInfo["H_start"] = hsv["H"]
	colorInfo["S_start"] = hsv["S"]
	colorInfo["V_start"] = hsv["V"]

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
	rgb["R"] = R
	rgb["G"] = G
	rgb["B"] = B
	rgb2hsv(rgb, hsv)

	colorInfo["H_end"] = hsv["H"]
	colorInfo["S_end"] = hsv["S"]
	colorInfo["V_end"] = hsv["V"]

	return 0
}
function set_12bit_color(frac, colorInfo,    r_max_cval, hsv, rgb, R, G, B) {

	hsv["H"] = frac * colorInfo["H_end"] + (1.0 - frac) * colorInfo["H_start"]
	hsv["S"] = frac * colorInfo["S_end"] + (1.0 - frac) * colorInfo["S_start"]
	hsv["V"] = frac * colorInfo["V_end"] + (1.0 - frac) * colorInfo["V_start"]
	hsv2rgb(hsv, rgb)

	r_max_cval = 1.0/15
	R = rgb["R"] / r_max_cval
	G = rgb["G"] / r_max_cval
	B = rgb["B"] / r_max_cval

	return sprintf("%x%x%x", R, G, B)
}
function rgb2hsv(rgb, hsv,   min, max, delta) {

	min = rgb["R"] < rgb["G"] ? rgb["R"] : rgb["G"]
	min = min      < rgb["B"] ? min      : rgb["B"]

	max = rgb["R"] > rgb["G"] ? rgb["R"] : rgb["G"]
	max = max      > rgb["B"] ? max      : rgb["B"]

	hsv["V"] = max

	delta = max - min
	if(delta < 0.00001){
		hsv["S"] = 0
		hsv["H"] = 0
		return
	}

	if(max > 0)
		hsv["S"] = (delta/max)
	else{
		hsv["S"] = 0
		hsv["H"] = 0	# V is 0, s H doesn't matter, so use 0
		return
	}
	if(rgb["R"] >= max)
		hsv["H"] = (rgb["G"] - rgb["B"])/delta		# between magenta & yellow
	else if(rgb["G"] >= max)
		hsv["H"] = 2.0 + (rgb["B"] - rgb["R"])/delta	# between yellow & cyan
	else
		hsv["H"] = 4.0 + (rgb["R"] - rgb["G"])/delta	# between cyan & magenta
	hsv["H"] *= 60
	if(hsv["H"] < 0)
		hsv["H"] += 360
	return
}
function hsv2rgb(hsv, rgb,    hh, p, q, t, ff, i) {

	if(hsv["S"] <= 0){
		rgb["R"] = hsv["V"]
		rgb["G"] = hsv["V"]
		rgb["B"] = hsv["V"]
		return
	}
	hh = hsv["H"]
	if(hh >= 360)
		hh = 0
	hh /= 60
	i = int(hh)
	ff = hh - i
	p = hsv["V"] * (1.0 - hsv["S"])
	q = hsv["V"] * (1.0 - (hsv["S"] * ff))
	t = hsv["V"] * (1.0 - (hsv["S"] * (1 - ff)))

	if(i == 0){
		rgb["R"] = hsv["V"]
		rgb["G"] = t
		rgb["B"] = p
	}else if(i == 1){
		rgb["R"] = q
		rgb["G"] = hsv["V"]
		rgb["B"] = p
	}else if(i == 2){
		rgb["R"] = p
		rgb["G"] = hsv["V"]
		rgb["B"] = t
	}else if(i == 3){
		rgb["R"] = p
		rgb["G"] = q
		rgb["B"] = hsv["V"]
	}else if(i == 4){
		rgb["R"] = t
		rgb["G"] = p
		rgb["B"] = hsv["V"]
	}else{	# must be 5
		rgb["R"] = hsv["V"]
		rgb["G"] = p
		rgb["B"] = q
	}
	return
}
function desat_12bit_color(color, val,   r_max_cval, R, G, B, rgb, hsv) {

	r_max_cval = 1.0/15

	R = (index("0123456789abcdef", tolower(substr(color, 1, 1))) - 1)/15.0
	G = (index("0123456789abcdef", tolower(substr(color, 2, 1))) - 1)/15.0
	B = (index("0123456789abcdef", tolower(substr(color, 3, 1))) - 1)/15.0

	rgb["R"] = R
	rgb["G"] = G
	rgb["B"] = B

	rgb2hsv(rgb, hsv)
	hsv["S"] *= sigmoid(val, 0.4, 8)
	hsv2rgb(hsv, rgb)
	return sprintf("%x%x%x", rgb["R"]/r_max_cval, rgb["G"]/r_max_cval, rgb["B"]/r_max_cval)
}
function sigmoid(x, s_min, alpha,    x_min, x_max, f_min, f_max, f_range, f_val) {
	x_min = 0 - 0.5
	x_max = 1 - 0.5
	f_min = 1 / (1 + exp(-alpha*x_min))
	f_max = 1 / (1 + exp(-alpha*x_max))
	f_range = f_max - f_min
	f_val = 1 / (1 + exp(-alpha*(x-0.5)))
	f_val = (f_val - f_min)/f_range		# now f has range [0,1]
	f_val = (1 - s_min) * f_val + s_min
	return f_val
}
