#!/usr/bin/env Rscript --vanilla

suppressMessages({
  
  library(ggplot2)
  library(optparse)
  library(RColorBrewer)
  library(DescTools)
  library(ggalluvial)
})


option_list = list(
  
  make_option( 
    c("-i", "--input"),
    type="character",
    default=NULL,
    help="input file......................[default = %default]"
  ) 
)

opt_parser = OptionParser(option_list = option_list, description = "")
opt = parse_args(opt_parser)

df = read.csv(opt$`input`, stringsAsFactors = F)