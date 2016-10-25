function rd_config(cfile, config,    err, n_cflines, cfline, nf, ary, i, tkey) {

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
