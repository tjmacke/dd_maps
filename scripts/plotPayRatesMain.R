#! /usr/local/bin/Rscript
#

args <- commandArgs(trailingOnly=T)

if (length(args) == 0) {
	stop('Missing pay file.', call.=F)
} else if (length(args) > 1) {
	stop('Only one pay file allowed.', call.=F)
}

df <- read.csv(args[1], sep='\t')
fn=sprintf('payRates.%s.pdf', format(Sys.time(), '%Y-%m-%d'))

source('./plotPayRates.R')
plotPayRates(df, fn)
