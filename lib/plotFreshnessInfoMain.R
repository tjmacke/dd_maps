dm_home <- Sys.getenv('DM_HOME')
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotFreshnessInfo.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

stype <- ''
dfn <- ''
i = 1
while(i <= length(args)) {
	if (args[i] == "-at") {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -at requires address-type argument', call.=F)
		}
		stype <- args[i]
	} else if(substring(args[i], 1, 1) == '-') {
		stop(paste('ERROR: unknown option', args[i], sep=': '), call.=F)
	} else {
		dfn <- args[i]
		break
	}
	i <- i + 1
}

if (i < length(args)) {
	stop('ERROR: extra arguments', call.=F)
}
if (stype == '') {
	stop('ERROR: missing -at { src | dst } argument', call.=F)
} else if(stype != 'src' && stype != 'dst') {
	stop(paste('ERROR: unknown address type', stype, 'must be src or dst', sep=' '), call.=F)
}

if (dfn == '') {
	stop('ERROR: missing site-evolution-file', call.=F)
}

df <- read.csv(dfn, sep='\t')
ofn <- sprintf('%sFreshness.%s.pdf', stype, format(Sys.time(), '%Y-%m-%d'))
pdf(file=ofn)
plotFreshnessInfo(df, stype, F)
