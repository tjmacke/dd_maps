plotSrcInfo <- function(df) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)

	dl <- makeDateLabels(df$date)

	# TODO: replace c(0, 10) with a properly scaled Y-Axis
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, 10),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab='Number of New Sources')

	axis(1, at=dl$tk, labels=F)
	y_adj <- 0.75
	text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
	axis(2, at=seq(from=0, to=10, by=1), labels=T, las=1)

	# draw a nice grid
	abline(h=seq(from=0, to=10, by=1), lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	if(length(df$date) >= 2) {
		lines(as.Date(df$date, '%Y-%m-%d'), df$nNewSources)
	} else {
		points(as.Date(df$date, '%Y-%m-%d'), df$nNewSources)
	}

	l_date <- df[length(df$date), 1]
	title(paste('New Delivery Sources', l_date, sep=' through '))
}
