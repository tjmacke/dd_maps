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

	if(atype == 'src') {
		df_yvals = df$nNewSources
		g_ylab = 'Number of New Sources'
		g_title = 'New Delivery Sources'
	} else {
		df_yvals = df$nNewDests
		g_ylab = 'Number of New Destinations'
		g_title = 'New Delivery Destinations'
	}

	# TODO: do this right, allow > 1 col
	if(app == 'ALL') {
		l_msg = 'ALL apps'
	} else {
		l_msg = sprintf('%s app', app)
	}

	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, y_max), # ORIG: c(0, 10),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab = g_ylab)

	l_date <- df[length(df$date), 1]
	if (multi) {
		axis(1, at=dl$tk, labels=F)
		y_adj <- 1
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.7)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(g_title, l_date, sep=' through '), cex.main=1)
	} else {
		axis(1, at=dl$tk, labels=F)
		y_adj <- 0.75
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(g_title, l_date, sep=' through '))
	}

	# draw a nice grid
	abline(h=ya_info, lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	if(length(df$date) >= 2) {
		lines(as.Date(df$date, '%Y-%m-%d'), df_yvals)
	} else {
		points(as.Date(df$date, '%Y-%m-%d'), df_yvals)
	}

	legend('topleft', inset=c(0.08, 0.02), bg='white',
		legend=c(l_msg),
		col=c('black'), lty=1, cex=ifelse(multi, 0.4, 0.7))
}
