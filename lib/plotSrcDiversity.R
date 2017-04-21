plotSrcDiversity <- function(df) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)
	
	dl <- makeDateLabels(df$date)

	# TODO: rplace c(0, 50) with a properly scaled Y-Axis
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, 50),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab='Number of Sources')

	l_date <- df[length(df$date), 1]
	axis(1, at=dl$tk, labels=F)
	y_adj <- 3.5
	text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
	axis(2, at=seq(from=0, to=50, by=10), labels=T, las=1)
	title(paste('Source Diversity', l_date, sep=' through '))

	# draw a nice grid
	abline(h=seq(from=0, to=50, by=10), lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	if (length(df$date) >= 2) {
		lines(as.Date(df$date, '%Y-%m-%d'), df$p10, col='red')
		lines(as.Date(df$date, '%Y-%m-%d'), df$p20, col='orange')
		lines(as.Date(df$date, '%Y-%m-%d'), df$p30, col='yellow')
		lines(as.Date(df$date, '%Y-%m-%d'), df$p40, col='green')
		lines(as.Date(df$date, '%Y-%m-%d'), df$p50, col='cyan')
	} else {
		points(as.Date(df$date, '%Y-%m-%d'), df$p10, col='red')
		points(as.Date(df$date, '%Y-%m-%d'), df$p20, col='orange')
		points(as.Date(df$date, '%Y-%m-%d'), df$p30, col='yellow')
		points(as.Date(df$date, '%Y-%m-%d'), df$p40, col='green')
		points(as.Date(df$date, '%Y-%m-%d'), df$p50, col='cyan')
	}

	legend('topleft', inset=c(0.05, 0.05), 
		legend = c('Top 10%', 'Top 20%', 'Top 30%', 'Top 40%', 'Top 50%'),
		col=c('red', 'orange', 'yellow', 'green', 'cyan'), lty=1, cex=1)
}
