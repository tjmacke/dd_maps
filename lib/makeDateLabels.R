makeDateLabels <- function(dv, posix=F) {

	u_dv <- paste(unique(substr(as.character(dv), 1, 7)), '01', sep='-')
	y_last <- strtoi(substr(u_dv[length(u_dv)], 1, 4), base=10)
	m_last <- strtoi(substr(u_dv[length(u_dv)], 6, 7), base=10)
	if (m_last == 12) {
		m_end = 1
		y_end = y_last + 1
	} else {
		m_end = m_last + 1
		y_end = y_last
	}
	lb <- c(u_dv, sprintf("%04d-%02d-01", y_end, m_end))
	if (posix) {
		p_lb <- paste(lb, '12:00:00', sep=' ')
		tk <- as.POSIXct(p_lb)
	} else {
		tk <- as.Date(lb, '%Y-%m-%d')
	}
	lb <- substr(lb, 1, 7)
	return(data.frame(tk, lb))
}
