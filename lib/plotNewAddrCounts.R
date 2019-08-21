plotNewAddrCounts <- function(df, atype, multi) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)
	sfn <- paste(dm_home, 'lib', 'getYaxisInfo.R', sep='/')
	source(sfn, chdir=T)

	dl <- makeDateLabels(df$date)
	ya_info <- getYaxisInfo(max(df$ALL))
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

	df[df == -1] <- NA
	pal <- c('red', 'green', 'blue', 'orange', 'cyan')

	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, y_max), # ORIG: c(0, 10),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab = g_ylab)

	# TODO: figure out how to get the srt dates in the right place
	l_date <- df[length(df$date), 1]
	if (multi) {
		axis(1, at=dl$tk, labels=F)
		y_adj <- 1
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.7)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(g_title, l_date, sep=' through '), cex.main=1)
	} else {
		axis(1, at=dl$tk, labels=F)
		y_adj <- 25
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(g_title, l_date, sep=' through '))
	}

	# draw a nice grid
	abline(h=ya_info, lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	# plot the data
	cnames <- colnames(df)
	l_colors <- c('black')
	if(nrow(df) > 1) {
		lines(as.Date(df$date, '%Y-%m-%d'), df[[2]], col='black')
		for (i in 3:length(cnames)) {
			lines(as.Date(df$date, '%Y-%m-%d'), df[[i]], col=pal[i-2])
			l_colors <- c(l_colors, pal[i-2])
		}
	} else {
		points(as.Date(df$date, '%Y-%m-%d'), df[[2]], col='black')
		for (i in 3:length(cnames)) {
			points(as.Date(df$date, '%Y-%m-%d'), df[[i]], col=pal[i-2])
			l_colors <- c(l_colors, pal[i-2])
		}
	}

	legend('topleft', inset=c(0.08, 0.02), bg='white',
		legend=cnames[2:length(cnames)],
		col=l_colors, lty=1, cex=ifelse(multi, 0.4, 0.7))
}
