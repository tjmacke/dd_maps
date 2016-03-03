plotPayRates <- function(df, fn) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)

	df <- read.csv(args[1], sep='\t')
	m_hrate <- lm(df$hrate ~ as.Date(df$date, '%Y-%m-%d'))
	m_drate <- lm(df$drate ~ as.Date(df$date, '%Y-%m-%d'))
	m_dph <- lm(df$dph ~ as.Date(df$date, '%Y-%m-%d'))

	pdf(file=fn)
	dl <- makeDateLabels(df$date)
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, 25),
		type='n',
		xlab='Date',
		xaxt='n',
		ylab='Rates ($/hr)')
	lines(as.Date(df$date, '%Y-%m-%d'), df$hrate, col='red')
	abline(m_hrate, col='red', lty=2)
	lines(as.Date(df$date, '%Y-%m-%d'), df$drate, col='green')
	abline(m_drate, col='green', lty=2)
	lines(as.Date(df$date, '%Y-%m-%d'), df$dph, col='blue')
	abline(m_dph, col='blue', lty=2)
	title('Doordash Rates')
	axis(1, at=dl$tk, labels=dl$lb)
	legend('bottomleft', inset=c(0.05, 0.2), legend=c('$/Hour', '$/Dash', 'Dashes/Hour'), col=c('red', 'green', 'blue'), lty=1)
}
