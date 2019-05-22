plotAddrInfo <- function(df, atype, app, multi) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)
	sfn <- paste(dm_home, 'lib', 'getYaxisInfo.R', sep='/')
	source(sfn, chdir=T)

	dl <- makeDateLabels(df$date)

	ya_info <- getYaxisInfo(max(ifelse(atype == 'src', df$nNewSources, df$nNewDests)))
	y_max = max(ya_info)

	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, y_max), # ORIG: c(0, 10),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab='Number of New Sources')

	l_date <- df[length(df$date), 1]
	if (multi) {
		axis(1, at=dl$tk, labels=F)
		y_adj <- 1
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.7)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste('New Delivery Sources', l_date, sep=' through '), cex.main=1)
	} else {
		axis(1, at=dl$tk, labels=F)
		y_adj <- 0.75
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste('New Delivery Sources', l_date, sep=' through '))
	}

	# draw a nice grid
	abline(h=ya_info, lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	if(length(df$date) >= 2) {
		lines(as.Date(df$date, '%Y-%m-%d'), ifelse(atype == 'src', df$nNewSources, df$nNewDests))
	} else {
		points(as.Date(df$date, '%Y-%m-%d'), ifelse(atype == 'src', df$nNewSources, df$nNewDests))
	}
}
