makeDateLabels <- function(dv) {
	u <- paste(unique(substr(as.character(dv), 1, 7)), '01', sep='-')

	y_last <- strtoi(substr(u[length(u)], 1, 4))
	m_last <- strtoi(substr(u[length(u)], 6, 7))

	y_last
	m_last

	if (m_last == 12) {
		m_end = 1
		y_end = y_last + 1
	} else {
		m_end = m_last + 1
		y_end = y_last
	}

	lb <- c(u, sprintf("%04d-%02d-01", y_end, m_end))
	tk <- as.Date(lb, '%Y-%m-%d')
	return(data.frame(tk, lb))
}
