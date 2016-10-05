plotPayRates <- function(df, pfn='') {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)

	m_hrate <- lm(df$hrate ~ as.Date(df$date, '%Y-%m-%d'))
	slope <- summary(m_hrate)$coefficients[2,1]
	d_hrate <- ifelse(slope > 0, 'Up', ifelse(slope == 0, 'Flat', 'Down'))
	m_drate <- lm(df$drate ~ as.Date(df$date, '%Y-%m-%d'))
	slope <- summary(m_drate)$coefficients[2,1]
	d_drate <- ifelse(slope > 0, 'Up', ifelse(slope == 0, 'Flat', 'Down'))
	m_dph <- lm(df$dph ~ as.Date(df$date, '%Y-%m-%d'))
	slope <- summary(m_dph)$coefficients[2,1]
	d_dph <- ifelse(slope > 0, 'Up', ifelse(slope == 0, 'Flat', 'Down'))

	if (pfn != '') {
		pdf(file=pfn)
	} else {
		x11()
	}
	dl <- makeDateLabels(df$date)
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, 35),
		type='n',
		xlab='Date',
		xaxt='n',
		yaxt='n',
		ylab='Rates ($/hr)')
	axis(side=2, at=seq(from=0, to=50, by=5), labels=T, las=1)
	grid(col='black')
	lines(as.Date(df$date, '%Y-%m-%d'), df$hrate, col='red')
	abline(m_hrate, col='red', lty=2)
	lines(as.Date(df$date, '%Y-%m-%d'), df$drate, col='green')
	abline(m_drate, col='green', lty=2)
	lines(as.Date(df$date, '%Y-%m-%d'), df$dph, col='blue')
	abline(m_dph, col='blue', lty=2)
	l_date <- df[length(df$date), 1]
	title(paste('Doordash Rates', l_date, sep=' through '))
	axis(1, at=dl$tk, labels=dl$lb)
	legend('topleft', inset=c(0.05, 0.05), bg='gray96',
		legend=c(paste('$/Hour', d_hrate, sep=', '), paste('$/Dash', d_drate, sep=', '), paste('Dashes/Hour', d_dph, sep=', ')),
		col=c('red', 'green', 'blue'), lty=1)
	if (pfn != '') {
		ign <- dev.off()
	}
}
