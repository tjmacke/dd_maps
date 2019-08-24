dm_home <- Sys.getenv('DM_HOME')
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotNewAddrCounts.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

atype <- ''
dfn <- ''
i = 1
while(i <= length(args)) {
	if (args[i] == "-at") {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -at requires address-type argument', call.=F)
		}
		atype <- args[i]
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
if (atype == '') {
	stop('ERROR: missing -at { src | dst } argument', call.=F)
} else if(atype != 'src' && atype != 'dst') {
	stop(paste('ERROR: unknown address type', atype, 'must be src or dst', sep=' '), call.=F)
}
if (dfn == '') {
	stop('ERROR: missing site-evolution-file', call.=F)
}

df <- read.csv(dfn, sep='\t')
df[df == -1] <- NA
ofn <- sprintf('new%s.%s.pdf', ifelse(atype == 'src', 'Sources', 'Dests'), format(Sys.time(), '%Y-%m-%d'))
pdf(file=ofn)
plotNewAddrCounts(df, atype, F)
