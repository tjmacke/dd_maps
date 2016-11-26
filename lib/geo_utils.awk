function GU_find_pgroups(start, count, longs, lats, pg_starts, pg_counts,   n_pgroups, l_geo, geo, i) {

	n_pgroups = 1
	pg_starts[n_pgroups] = start
	pg_counts[n_pgroups] = 1
	l_geo[1] = longs[start]
	l_geo[2] = lats[start]
	for(i = 1; i < count; i++){
		geo[1] = longs[start + i]
		geo[2] = longs[start + i]
		if(GU_geo_equal(geo, l_geo)){
			pg_counts[n_pgroups]++
		}else{
			n_pgroups++
			pg_starts[n_pgroups] = start + i
			pg_counts[n_pgroups] = 1
		}
		l_geo[1] = geo[1]
		l_geo[2] = geo[2]
	}

	return n_pgroups
}
function GU_geo_equal(g1, g2) {
	return g1[1] == g2[1] && g1[2] == g2[2]
}
function GU_geo_isnull(g) {
	return g[1] == "" || g[2] == ""
}
function GU_geo_adjust(long, lat, n, long_adj, lat_adj,   PI, RAD, i, a) {

	PI = 4.0 * atan2(1, 1)
	RAD = 0.0001

	long_adj[1] = 0
	lat_adj[1] = 0
	if(n > 1){
		a = 2.0*PI/(n-1)
		for(i = 2; i <= n; i++){
			long_adj[i] = RAD * sin(a * (i-2))
			lat_adj[i] = RAD * cos(a * (i-2))
		}
	}
}
function GU_gc_dist(lng_1, lat_1, lng_2, lat_2,   R_EARTH, D2R, ph1_1, phi_2, delta_phi, delta_lambda, a, c) {

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
