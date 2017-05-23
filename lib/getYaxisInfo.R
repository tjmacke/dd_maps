getYaxisInfo <- function(v_max) {

	if (v_max < 10)
		return(seq(from=0, to=10, by=1))

	p10 <- as.integer(log10(v_max))
	rv_max <- v_max/(10^p10)
	i_mult <- ifelse(rv_max >= 7, 10, ifelse(rv_max >= 3, 5, ifelse(rv_max >= 1.5, 2, 1)))
	incr <- i_mult * 10^(p10-1)
	n_ticks <- as.integer(v_max %/% incr) + 1
	return(seq(from=0, to=n_ticks*incr, by=incr))
}
