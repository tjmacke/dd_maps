#! /usr/local/bin/Rscript
#

args <- commandArgs(trailingOnly=T)

if (length(args) == 0) {
	stop('Missing new source file.', call.=F)
} else if (length(args) > 1) {
	stop('Only one new source file allowed.', call.=F)
}

df <- read.csv(args[1], sep='\t')
fn = file = sprintf('newSources.%s.pdf', format(Sys.time(), '%Y-%m-%d'))

source('./plotSrcInfo.R')
plotSrcInfo(df, fn)
