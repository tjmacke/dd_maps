plotSiteFreshness <- function(df, stype, pfn='') {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=T)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)

	if (pfn != '') {
		pdf(file=pfn)
	} else {
		X11()
	}
	dl <- makeDateLabels(df$date)

	# TODO: replace c(0, 60) with a properly scaled Y-Axis
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, 60),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab='Percent Fresh by Time')

	axis(1, at=dl$tk, label=F)
	y_adj <- 4.2
	text(dl$tk, y = 0 - y_adj, label=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
	axis(2, at=seq(from=0, to=100, by=10), labels=T, las=1)

	# draw a nice grid
	abline(h=seq(from=0, to=100, by=10), lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	# TODO: require > 1 point?
	lines(as.Date(df$date, '%Y-%m-%d'), df$le1, lwd=1.5, col='red')
	lines(as.Date(df$date, '%Y-%m-%d'), df$le2, lwd=1.5, col='orange')
	lines(as.Date(df$date, '%Y-%m-%d'), df$le4, lwd=1.5, col='yellow')
	lines(as.Date(df$date, '%Y-%m-%d'), df$le8, lwd=1.5, col='green')
	lines(as.Date(df$date, '%Y-%m-%d'), df$le12, lwd=1.5, col='cyan')
	lines(as.Date(df$date, '%Y-%m-%d'), df$le26, lwd=1.5, col='lightblue')
	lines(as.Date(df$date, '%Y-%m-%d'), df$le52, lwd=1.5, col='gray')
	lines(as.Date(df$date, '%Y-%m-%d'), df$gt52, lwd=1.5, col='black')

	l_date <- substr(df[length(df$date), 1], 1, 7)
	title(paste(stype, ' Freshness through ', l_date, sep=''))

	lgnd = c('<= 1 week', '<= 2 weeks', '<= 4 weeks', '<= 8 weeks', '<= 12 weeks', '<= 26 weeks', '<= 52 weeks', '> 52 weeks')
	legend('topleft', inset=c(0.08, 0.02), bg='white',
		legend=lgnd,
		col=c('red', 'orange', 'yellow', 'green', 'cyan', 'lightblue', 'gray', 'black'), lty=1, cex=0.7)

	if (pfn != '') {
		ign <- dev.off()
	}
}
