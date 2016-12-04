function CFG_read(cfile, config,    err, n_cflines, cfline, nf, ary, i, tkey) {

	err = 0
	for(n_cflines = 0; (getline cfline < cfile) > 0; ){
		n_cflines++
		if(substr(cfline, 1, 1) == "#")
			continue;
		# TODO: redo to split on the first eq sign
		nf = split(cfline, ary, "=")
		for(i = 1; i <= nf; i++){
			gsub(/^[\t  ]*/, "", ary[i])
			gsub(/[\t  ]*$/, "", ary[i])
		}
		if(ary[1] == "")
			continue
		if(substr(ary[1], 1, 1) == "#")
			continue
		if(nf == 1){
			if(ary[1] != "}"){
				printf("ERROR: line %7d: unrecognized stmt: %s\n", n_cflines, ary[1]) > "/dev/stderr"
				err = 1
				break
			}
			tkey = ""
		}else if(nf > 2){
			printf("ERROR: line %7d: too many fields: %d, expect 1 or 2\n", n_cflines, nf) > "/dev/stderr"
			err = 1
			break
		}else if(ary[2] == "{"){
			tkey = ary[1]
		}else if(tkey == ""){
			config["_globals", ary[1]] = ary[2]
		}else{
			config[tkey, ary[1]] = ary[2]
		}
	}
	close(cfile)
	return err
}
function CFG_dump(file, config,   ng, k, keys, nk, k1tab, k1, nk2, k2tab, k2tab_srt, k2) {

	ng = 0
	for(k in config){
		nk = split(k, keys, SUBSEP)
		if(keys[1] == "_globals"){
			ng++
			k2tab[keys[2]] = 1
		}else
			k1tab[keys[1]] = 1
	}
	if(ng > 0){
		nk2 = asorti(k2tab, k2tab_srt)
		for(k2 = 1; k2 <= nk2; k2++)
			printf("%s = %s\n", k2tab_srt[k2], config["_globals", k2tab_srt[k2]]) > file
		delete k2tab_srt
		delete k2tab
	}
	for(k1 in k1tab){
		for(k in config){
			nk = split(k, keys, SUBSEP)
			if(keys[1] == k1)
				k2tab[keys[2]] = 1
		}
		nk2 = asorti(k2tab, k2tab_srt)
		printf("%s = {\n", k1) > file
		for(k2 = 1; k2 <= nk2; k2++)
			printf("\t%s = %s\n", k2tab_srt[k2], config[k1, k2tab_srt[k2]]) > file
		printf("}\n") > file
		delete k2tab_srt
		delete k2tab
	}
}
