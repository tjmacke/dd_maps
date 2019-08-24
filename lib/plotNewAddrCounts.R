plotNewAddrCounts <- function(df, atype, multi) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'getYaxisInfo.R', sep='/')
	source(sfn, chdir=T)

	# line colors
	pal <- c('red', 'green', 'blue', 'orange', 'cyan')
	# control placement of X axis tick labels
	xt_adj <- 0.03

	ya_info <- getYaxisInfo(max(df$ALL, na.rm=T))
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

	tmin <- as.Date(df$date[1], '%Y-%m-%d')
	tmax <- as.Date(df$date[nrow(df)], '%Y-%m-%d')
	tlab <- seq(tmin, tmax, by='month')
	lab <- format(tlab, '%Y-%m')

	# plot the data
	cnames <- colnames(df)
	l_colors <- c('black')
	if(nrow(df) > 1) {
		plot(as.Date(df$date, '%Y-%m-%d'), df[[2]], t='l', xaxt='n', xlab='Month', yaxt='n', ylab=g_ylab)
		axis(1, at=tlab, labels=F)
		text(x=tlab, y=par()$usr[3]-xt_adj*(par()$usr[4]-par()$usr[3]), labels=lab, cex=0.7, srt=45, adj=1, xpd=T)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(g_title, df$date[nrow(df)-1], sep=' through '), cex.main=1)
		for (i in 3:length(cnames)) {
			lines(as.Date(df$date, '%Y-%m-%d'), df[[i]], col=pal[i-2])
			l_colors <- c(l_colors, pal[i-2])
		}
	} else {
		plot(as.Date(df$date, '%Y-%m-%d'), df[[2]], t='p', xaxt='n', xlab='date', yaxt='n', ylab=g_ylab)
		axis(1, at=tlab, labels=F)
		text(x=tlab, y=par()$usr[3]-xt_adj*(par()$usr[4]-par()$usr[3]), labels=lab, srt=45, adj=1, xpd=T)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste(g_title, df$date[nrow(df)-1], sep=' through '), cex.main=1)
		for (i in 3:length(cnames)) {
			points(as.Date(df$date, '%Y-%m-%d'), df[[i]], col=pal[i-2])
			l_colors <- c(l_colors, pal[i-2])
		}
	}

	# draw a nice grid
	abline(h=ya_info, lty=3, col='black')
	abline(v=tlab, lty=3, col='black')

	legend('topleft', inset=c(0.08, 0.02), bg='white',
		legend=cnames[2:length(cnames)],
		col=l_colors, lty=1, cex=ifelse(multi, 0.4, 0.7))
}
