dm_home <- Sys.getenv('DM_HOME')
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotSrcDiversity.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

if (length(args) == 0) {
	stop('Missing new source file.', call.=F)
} else if (length(args) > 1) {
	stop('Only one new source file allowed.', call.=F)
}

df <- read.csv(args[1], sep='\t')
ofn <- sprintf('srcDiversity.%s.pdf', format(Sys.time(), '%Y-%m-%d'))
pdf(file=ofn)
plotSrcDiversity(df)
