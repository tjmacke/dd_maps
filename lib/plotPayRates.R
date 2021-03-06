plotPayRates <- function(df, multi) {

	if (!exists('dm_home')) {
		stop('dm_home is not defined.', call.=F)
	}
	sfn <- paste(dm_home, 'lib', 'makeDateLabels.R', sep='/')
	source(sfn, chdir=T)
	sfn <- paste(dm_home, 'lib', 'getYaxisInfo.R', sep='/')
	source(sfn, chdir=T)

	if(length(df$date) >=2) {
		if(length(df$date) >=3 ){
			m_hrate <- lm(df$hrate ~ as.Date(df$date, '%Y-%m-%d'))
			s_hrate <- summary(m_hrate)$coefficients[2,1]

			m_drate <- lm(df$drate ~ as.Date(df$date, '%Y-%m-%d'))
			s_drate <- summary(m_drate)$coefficients[2,1]

			m_dph <- lm(df$dph ~ as.Date(df$date, '%Y-%m-%d'))
			s_dph <- summary(m_dph)$coefficients[2,1]
		} else {
			# All I care about is the sign, so ...
			s_hrate <- df$hrate[2] - df$hrate[1]		
			s_drate <- df$drate[2] - df$drate[1]		
			s_dph <- df$dph[2] - df$dph[1]		
		}
		d_hrate <- ifelse(s_hrate > 0, 'Up', ifelse(s_hrate == 0, 'Flat', 'Down'))
		d_drate <- ifelse(s_drate > 0, 'Up', ifelse(s_drate == 0, 'Flat', 'Down'))
		d_dph <- ifelse(s_dph > 0, 'Up', ifelse(s_dph == 0, 'Flat', 'Down'))
	}

	dl <- makeDateLabels(df$date)

	ya_info <- getYaxisInfo(max(max(df$hrate), max(df$drate), max(df$dph)))
	y_max <- max(ya_info)
	plot(
		c(as.Date(dl$tk[1], '%Y-%m-%d'), as.Date(dl$tk[length(dl$tk)], '%Y-%m-%d')),
		c(0, y_max),
		type='n',
		xlab='Month',
		xaxt='n',
		yaxt='n',
		ylab='Rates ($/hr)')

	l_date <- df[length(df$date), 1]
	if (multi) {
		y_adj <- 4
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.7)
		axis(1, at=dl$tk, labels=F)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste('Doordash Rates', l_date, sep=' through '), cex.main=1)
	} else {
		y_adj <- 2.7
		text(dl$tk, y = 0 - y_adj, labels=dl$lb, srt=45, pos=2, off=-0.2, xpd=T, cex=0.8)
		axis(1, at=dl$tk, labels=F)
		axis(2, at=ya_info, labels=ya_info, las=1)
		title(paste('Doordash Rates', l_date, sep=' through '))
	}

	# draw a nice grid
	abline(h=ya_info, lty=3, col='black')
	abline(v=dl$tk, lty=3, col='black')

	if(length(df$date) >= 2) {
		lines(as.Date(df$date, '%Y-%m-%d'), df$hrate, col='red')
		lines(as.Date(df$date, '%Y-%m-%d'), df$drate, col='green')
		lines(as.Date(df$date, '%Y-%m-%d'), df$dph, col='blue')

		if(length(df$date) >= 3) {
			abline(m_hrate, col='red', lty=2)
			abline(m_drate, col='green', lty=2)
			abline(m_dph, col='blue', lty=2)
		}
	} else {
		points(as.Date(df$date, '%Y-%m-%d'), df$hrate, col='red')
		points(as.Date(df$date, '%Y-%m-%d'), df$drate, col='green')
		points(as.Date(df$date, '%Y-%m-%d'), df$dph, col='blue')
	}

	if(length(df$date) >= 2) {
		lgnd <- c(paste('$/Hour', d_hrate, sep=', '), paste('$/Dash', d_drate, sep=', '), paste('Dashes/Hour', d_dph, sep=', '))
	} else {
		lgnd <- c('$/Hour', '$/Dash', 'Dashes/Hour')
	}
	legend('topleft', inset=c(0.05, 0.05), bg='gray96',
		legend=lgnd,
		col=c('red', 'green', 'blue'), lty=1, cex=ifelse(multi, 0.4, 1))
}
