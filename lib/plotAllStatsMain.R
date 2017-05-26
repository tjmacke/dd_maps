dm_home <- Sys.getenv('DM_HOME')
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotPayRates.R', sep='/')
source(sfn, chdir=T)
sfn <- paste(dm_home, 'lib', 'plotSrcInfo.R', sep='/')
source(sfn, chdir=T)
sfn <- paste(dm_home, 'lib', 'plotFreshnessInfo.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

p_fn <- ''
s_fn <- ''
sf_fn <- ''
df_fn <- ''
i = 1
while (i <= length(args)) {
	if (args[i] == '-p') {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -p requires pay-file argument', call.=F)
		}
		p_fn <- args[i]
	} else if (args[i] == '-s') {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -s requires src-file argument', call.=F)
		}
		s_fn <- args[i]
	} else if (args[i] == '-sf') {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -sf requires src-freshness-file argument', call.=F)
		}
		sf_fn <- args[i]
	} else if (args[i] == '-df') {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -df requires dst-freshness-file argument', call.=F)
		}
		df_fn <- args[i]
	} else {
		stop(paste('ERROR: unknown option', args[i], sep=': '), call.=F)
	}
	i <- i + 1
}

if (p_fn == '') {
	stop('ERROR: missing -p pay-file argument', call.=F)
}
if (s_fn == '') {
	stop('ERROR: missing -s src-file argument', call.=F)
}
if (sf_fn == '') {
	stop('ERROR: missing -sf src-freshness-file argument', call.=F)
}
if (df_fn == '') {
	stop('ERROR: missing -df dst-freshness-file argument', call.=F)
}

p_df <- read.csv(p_fn, sep='\t')
s_df <- read.csv(s_fn, sep='\t')
sf_df <- read.csv(sf_fn, sep='\t')
df_df <- read.csv(df_fn, sep='\t')

# All grafx must follow the pdf() stmt
ofn <- sprintf('allStats.%s.pdf', format(Sys.time(), '%Y-%m-%d'))
pdf(file=ofn)

par(mfcol=c(2,2), oma=c(0,0,3,0))

plotPayRates(p_df, T)
plotSrcInfo(s_df, T)
plotFreshnessInfo(sf_df, 'src', T)
plotFreshnessInfo(df_df, 'dst', T)

ign <- dev.off()
