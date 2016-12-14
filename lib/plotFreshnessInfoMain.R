dm_home <- Sys.getenv(c('DM_HOME'))
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotSiteFreshness.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

stype <- ''
dfn <- ''

i = 1
while(i <= length(args)) {
	if (args[i] == "-at") {
		i <- i + 1
		if (i == length(args)) {
			stop('ERROR: -at requires address-type argument', call.=F)
		}
		stype <- args[i]
	} else if(substring(args[i], 1, 1) == '-') {
		stop(paste('ERROR: unknown option', args[i], sep=': '))
	} else {
		dfn <- args[i]
		break
	}
	i <- i + 1
}

if (i < length(args)) {
	stop('ERROR: extra arguments')
}
if (stype == '') {
	stop('ERROR: missing -at { src | dst } argument')
} else if(stype != 'src' && stype != 'dst') {
	stop(paste('ERROR: unknown address type', stype, 'must be src or dst', sep=' '))
}

if (dfn == '') {
	stop('ERROR: missing site-evolution-file')
}

df <- read.csv(dfn, sep='\t')
ofn = sprintf('%sFreshness.%s.pdf', stype, format(Sys.time(), '%Y-%m-%d'))

plotSiteFreshness(df, stype, ofn)
