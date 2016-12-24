dm_home <- Sys.getenv(c('DM_HOME'))
if (dm_home == '') {
	stop('DM_HOME is not defined.', call.=F)
}
sfn <- paste(dm_home, 'lib', 'plotPayRates.R', sep='/')
source(sfn, chdir=T)

args <- commandArgs(trailingOnly=T)

if (length(args) == 0) {
	stop('Missing pay file.', call.=F)
} else if (length(args) > 1) {
	stop('Only one pay file allowed.', call.=F)
}

df <- read.csv(args[1], sep='\t')
ofn=sprintf('payRates.%s.pdf', format(Sys.time(), '%Y-%m-%d'))
pdf(file=ofn)
plotPayRates(df)
