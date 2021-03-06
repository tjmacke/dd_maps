plotFreshnessInfo <- function(df, atype, multi) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=T)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)
	sfn <- paste(dm_home, 'lib', 'getYaxisInfo.R', sep='/')
	source(sfn, chdir=T)

	dl <- makeDateLabels(df$date)

	ya_info <- getYaxisInfo(max(max(df$le1), max(df$le2), max(df$le4), max(df$le8), max(df$le12), max(df$le26), max(df$le52), max(df$gt52)))
	y_max <- max(ya_info)
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, y_max),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab='Percent Fresh by Time')

	l_date <- substr(df[length(df$date), 1], 1, 7)
	if (multi) {
		y_adj <- 7
		text(dl$tk, y = 0 - y_adj, label=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.7)
		axis(1, at=dl$tk, label=F)
		axis(2, at=ya_info, labels=ya_info, las=1, cex=0.8)
		title(paste(atype, ' Freshness through ', l_date, sep=''), cex.main=1)
	} else {
		y_adj <- 4.2
		text(dl$tk, y = 0 - y_adj, label=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
		axis(1, at=dl$tk, label=F)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(atype, ' Freshness through ', l_date, sep=''))
	}

	# draw a nice grid
	abline(h=ya_info, lty=3, col='black')
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

	legend('topleft', inset=c(0.08, 0.02), bg='white',
		legend=c('<= 1 week', '<= 2 weeks', '<= 4 weeks', '<= 8 weeks', '<= 12 weeks', '<= 26 weeks', '<= 52 weeks', '> 52 weeks'),
		col=c('red', 'orange', 'yellow', 'green', 'cyan', 'lightblue', 'gray', 'black'), lty=1, cex=ifelse(multi, 0.4, 0.7))
}
