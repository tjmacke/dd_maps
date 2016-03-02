source('./makeDateLabels.R')

plotSrcInfo <- function(df, fn) {

	pdf(file = fn)
	dl <- makeDateLabels(df$date)
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, 10),
		type='n',
		xlab='Date',
		xaxt='n',
		ylab='Number of New Sources')
	lines(as.Date(df$date, '%Y-%m-%d'), df$nNewSources)
	axis(1, at=dl$tk, labels=dl$lb)
	title('New Delivery Sources')
}
