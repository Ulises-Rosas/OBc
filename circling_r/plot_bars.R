#!/usr/bin/env Rscript

suppressMessages({
  
  library(ggplot2)
  library(optparse)
  library(RColorBrewer)
})

option_list = list(
  
  make_option( 
    c("-i", "--input"),
    type="character",
    default=NULL,
    help="input file......................[default = %default]"
  ),
  make_option( 
    c("-v", "--var"),
    type="character",
    default="region",
    help="Variables at y axis.............[default = %default]"
  ),
  make_option( 
    c("-f", "--fill"),
    type="character",
    default="subgroup",
    help="Factor for ploting on each bar..[Default = %default]"
  ),
  make_option( 
    c("-x", "--xtitle"),
    type="character",
    default="Proportion",
    help="Title for x axis................[Default = %default]"
  ),
  make_option( 
    c("-y", "--ytitle"),
    type="character",
    default="Country",
    help="Title for y axis................[Default = %default]"
  ),
  make_option( 
    c("-l", "--ltitle"),
    type="character",
    default="Taxa",
    help="Title for legend................[Default = %default]"
  ),
  make_option( 
    c("-p", "--palette"),
    type="character",
    default="Spectral",
    help="Palette of colors...............[Default = %default]"
  ),
  make_option( 
    c("-H", "--height"),
    type="numeric",
    default=4.25,
    help="Height of plot..................[Default = %default]"
  ),
  make_option( 
    c("-W", "--width"),
    type="numeric",
    default=10.5,
    help="Width of plot...................[Default = %default]"
  ),
  make_option( 
    c("-r", "--resolution"),
    type="numeric",
    default=100,
    help="Resolution of plot..............[Default = %default]"
  ),
  make_option( 
    c("-s", "--sortVar"),
    type="character",
    default=NULL,
    help="Sort var by an specific string..[Default = %default]"
  ),
  make_option( 
    c("-S", "--sortFill"),
    type="character",
    default=NULL,
    help="Sort fill by an specific string.[Default = %default]"
  ),
  make_option( 
    c("-o", "--output"),
    type="character",
    default="input_based",
    help="output file.....................[default = <%default>]"
  )
)

opt_parser = OptionParser(option_list = option_list, description = "")
opt = parse_args(opt_parser)

df = read.csv(opt$`input`, stringsAsFactors = F)

## delete
# df = read.csv('C45981549E', stringsAsFactors = F)
## delete

sorter <- function(df, col, decreasing = T){
  
  do.call("rbind",
          lapply(
            unique(df[, col]), 
            function(x){
              tmp_sum = sum(df[grepl(x, df[, col]),'n'])
              data.frame(fill = x, tmp_sum, stringsAsFactors = F)
              }) 
          ) ->  tmp_df
  
  return( tmp_df[order(tmp_df$tmp_sum, decreasing = decreasing),]$fill )
}

scaleY <- function(df){
  
  if( length( integer(df[1, 'n']) ) == 0 ){
    
    return( as.character( seq(0, 1, length.out = 5) ) )
  }else{
    
    return( as.character( seq(min(df[, 'n']), max(df[, 'n']), length.out = 5) ) )
  }
}


suppressWarnings({
  cols1 = colorRampPalette(brewer.pal(12, opt$`palette`))(length(unique(df[,opt$`fill`])))
})

fillLevels <- if (!is.null(opt$`sortFill`)) strsplit(opt$`sortFill`,"," )[[1]] else sorter(df,opt$`fill`)
varLevels  <- if (!is.null(opt$`sortVar` )) strsplit(opt$`sortVar`, "," )[[1]] else sorter(df,opt$`var` )

df[,opt$`fill`] <- factor(x = df[,opt$`fill`], levels = fillLevels, ordered = T )
df[,opt$`var`]  <- factor(x = df[,opt$`var`] , levels = varLevels , ordered = T )


jpeg(filename = opt$`output`, 
     width    = opt$`width`,
     height   = opt$`height`, 
     units    = 'in', 
     res      = opt$`resolution`)
ggplot(df,
       aes_string(
         fill = opt$`fill`,
         y = "-n",
         x = opt$`var` )) +
  geom_bar(stat = "identity") +
  theme_bw(base_size = 15) +
  scale_fill_manual(values = cols1, name = opt$`ltitle`) +
  scale_y_continuous(labels = scaleY(df)) +
  coord_flip() +
  labs(    y = opt$`xtitle`,
           x = opt$`ytitle`,
           title = NULL ) +
  theme(plot.title  = element_text( size = 19 ),
        axis.text.y = element_text( size = 11 , hjust = 0 ),
        axis.text.x = element_text( size = 11 ))
invisible(dev.off())

quit(save = "no", runLast = F, status = 0)
