function gc_dist(lng_1, lat_1, lng_2, lat_2,   R_EARTH, D2R, ph1_1, phi_2, delta_phi, delta_lambda, a, c) {

	R_EARTH = 3.959e3	# mean radius in miles
	D2R = (2*atan2(0, -1))/360.0
	phi_1 = lat_1 * D2R
	phi_2 = lat_2 * D2R
	delta_phi = (lat_2 - lat_1) * D2R
	delta_lambda = (lng_2 - lng_1) * D2R
	a = sin(delta_phi/2.0) * sin(delta_phi/2.0) + cos(phi_1) * cos(phi_2) * sin(delta_lambda/2.0) * sin(delta_lambda/2.0)
	c = 2 * atan2(sqrt(a), sqrt(1.0-a))
	return R_EARTH * c
}
