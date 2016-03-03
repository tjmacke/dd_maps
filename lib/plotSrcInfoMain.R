dm_home <- Sys.getenv('DM_HOME')
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=T)
}
dm_lib <- paste(dm_home, 'lib', sep='/')

args <- commandArgs(trailingOnly=T)

if (length(args) == 0) {
	stop('Missing new source file.', call.=F)
} else if (length(args) > 1) {
	stop('Only one new source file allowed.', call.=F)
}

df <- read.csv(args[1], sep='\t')
ofn = file = sprintf('newSources.%s.pdf', format(Sys.time(), '%Y-%m-%d'))

sfn <- paste(dm_lib, 'plotSrcInfo.R', sep='/')
source(sfn, chdir=T)
plotSrcInfo(df, ofn)
