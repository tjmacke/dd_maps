dm_home <- Sys.getenv('DM_HOME')
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotAddrInfo.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

atype <- ''
app <- ''
dfn <- ''
i = 1
while(i <= length(args)) {
	if (args[i] == "-at") {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -at requires address-type argument', call.=F)
		}
		atype <- args[i]
	} else if (args[i] == "-app") {
		i <- i + 1
		if (i > length(args)) {
			stop('ERROR: -app requires app-name argument', call.=F)
		}
		app <- args[i]
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
} else if(app != 'any' && app != 'gh' && app != 'dd' && app != 'pm' && app != 'ue') {
	stop(paste('ERROR: unknown app', app, 'must be one of gh, dd, pm, ue or any', sep=' '), call.=F)
}
if (dfn == '') {
	stop('ERROR: missing site-evolution-file', call.=F)
}

df <- read.csv(dfn, sep='\t')
ofn <- sprintf('newSources.%s.pdf', format(Sys.time(), '%Y-%m-%d'))
pdf(file=ofn)
plotAddrInfo(df, atype, app, F)
