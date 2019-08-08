#!/usr/bin/env Rscript --vanilla


suppressWarnings({
  
  suppressMessages({
    
    library(ggplot2)
    library(optparse)
    library(RColorBrewer)
    library(DescTools)
    library(ggpubr)
    library(cowplot)
  })
})


# > ARGS[@]::Start ####
option_list = list(
  
  make_option( 
    c("-i", "--input"),
    type="character",
    default=NULL,
    help="input file......................[default = %default]"
  ),
  make_option( 
    c("-y", "--barplot"),
    type="character",
    default=NULL,
    help="input file......................[default = %default]"
  ),
  make_option( 
    c("-b", "--block"),
    type="character",
    default=NULL,
    help="Sort block by an specific string..[Default = %default]"
  ),
  make_option( 
    c("-l", "--lines"),
    type="character",
    default=NULL,
    help="Sort lines by an specific string..[Default = %default]"
  ),
  make_option( 
    c("-p", "--palette"),
    type="character",
    default="RdYlBu",
    help="Palette of colors...............[Default = %default]"
  ),
  make_option( 
    c("-P", "--pointsize"),
    type="numeric",
    default=3.25,
    help="Point size inside dumbbell plot..[Default = %default]"
  ),
  make_option( 
    c("-T", "--textsize"),
    type="numeric",
    default=3.25,
    help="Text size above bars.............[Default = %default]"
  ),
  make_option( 
    c("-B", "--basesize"),
    type="numeric",
    default=14,
    help="Size of labels..................[Default = %default]"
  ),
  make_option( 
    c("-H", "--height"),
    type="numeric",
    default=3.5,
    help="Height of plot..................[Default = %default]"
  ),
  make_option( 
    c("-W", "--width"),
    type="numeric",
    default=13.8,
    help="Width of plot...................[Default = %default]"
  ),
  make_option( 
    c("-r", "--resolution"),
    type="numeric",
    default=100,
    help="Resolution of plot..............[Default = %default]"
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
# < ARGS[@]::END   ####

### params ####
# opt = list()
# opt$`input` = "C0E64BD8B76243"
# opt$`barplot` = "FC78E7380ACD44"
# opt$`palette` = "RdYlBu"
# opt$`lines` = NULL
# opt$`width` = 12.5
# opt$`height` = 3.25
# opt$textsize = 3.25
# opt$basesize = 14
# opt$pointsize = 3.25
# opt$`resolution` = 100
# opt$`output` = "testUpset.jpeg"
### params ####

# > loadData::Start ####
UpsetData = read.csv(opt$`input`, stringsAsFactors = F)

SubStrGroup = gsub( "^([A-Za-z]+).*","\\1", UpsetData$patternUsedPlusGroup)
MajorGroups = unique(SubStrGroup)

factor(SubStrGroup, 
       levels  = MajorGroups,
       ordered = T)  -> UpsetData$barGroup

factor(
  UpsetData$patternUsedPlusGroup,
  levels  = UpsetData$patternUsedPlusGroup,
  ordered = T) -> UpsetData$patternUsedPlusGroup 
# < loadData::End   ####

# > Colors::Start ####
suppressWarnings({ 
  cols1 = colorRampPalette( brewer.pal(12, opt$`palette`) )( length(MajorGroups) ) 
  names(cols1) <- MajorGroups
  })
fillcol = DescTools::MixColor(col1 = "black", col2 = cols1, 0.3)
names(fillcol) <- MajorGroups
textcol = DescTools::MixColor(col1 = "black", col2 = cols1, 0.7)
names(textcol) <- MajorGroups
# < Colors::End   ####

# > ggplotThemeBase::Start ####
base_theme <- function(base_size = opt$`basesize`, type = "hist"){
  theme_bw(base_size = base_size) %+replace%
    theme(
      legend.position   = "none"
      ,panel.border     = element_blank()
      ,panel.grid.major = element_blank()
      ,panel.grid.minor = element_blank() 
      ) -> baseLine
  
  if ( type == "hist") {
    baseLine %+replace%
      theme( axis.text.x.bottom = element_blank() ) -> q
    
  }else if ( type == "bar" ) {
    baseLine %+replace%
      theme(
        axis.ticks.y = element_blank()
        ,axis.text.y = element_blank()
      ) -> q
    
  }else if ( type == "dumb" ) {
    baseLine %+replace%
      theme(
        axis.text.x.bottom = element_blank() 
        ,axis.ticks.x=element_blank() 
      ) -> q
  }
  return(q)
}
# < ggplotThemeBase::End   ####

# > Hist::Start ####
df = data.frame( SubStrGroup, 
                 pos = seq_along(SubStrGroup),
                 stringsAsFactors = F)

do.call('rbind',
        lapply(
          MajorGroups,
          function(x){
            tmp_rank = range( df[ grepl( x, df$SubStrGroup), ]$pos ) + c(-.5,.5)
            data.frame( y1 = 0, y2 = Inf, x1 = tmp_rank[1], x2 = tmp_rank[2], Group = x )
            })
        ) -> df_geom_rect

factor(SubStrGroup, 
       levels = MajorGroups,
       ordered = T) -> UpsetData$barGroup

ggplot() +
  geom_bar(data = UpsetData ,
           aes(y = sharing, x = patternUsedPlusGroup),
           stat  = "identity",
           color = "transparent", 
           fill  = "transparent") +
  geom_rect( data        = df_geom_rect,
             mapping     = aes(xmin = x1, xmax = x2, ymin = y1, ymax = y2, fill = Group),
             inherit.aes = F,
             fill = alpha( cols1, 0.5 ), 
             show.legend = F) +
  geom_bar(data = UpsetData ,
           aes(y = sharing, 
               x = patternUsedPlusGroup, 
               fill = barGroup),
           stat = "identity", 
           color ="transparent") +
  scale_fill_manual(values = fillcol,
                    name   = "Taxonomical\ngroups" )+
  #Size were changed from 3.25 to 4.25
  geom_text(data = UpsetData,
            aes(y = sharing,
                x = patternUsedPlusGroup, 
                label  = N, 
                colour = barGroup),
            angle = 90,
            hjust = -0.1,
            size  = opt$`textsize`,
            show.legend = F )+
  scale_color_manual(values = textcol)+
  labs(x =  NULL, y = NULL) + 
  scale_y_continuous(
    labels = function(y) paste0(y, "%") ,
    limits = c(0,100),
    expand = c(0,0) ) +
  base_theme(type = "hist") +
  theme(plot.margin = unit(c(0.15,0,0.05,0),"cm")) ->   hist
# < Hist::End   ####

# > Legend::Start ####
hist +
  theme(legend.position="left") +
  guides(fill = guide_legend(label.position = "left", label.hjust = 1)) -> hist_legend 

pdf(file = NULL) ## avoiding cowplot/ggplot bug
ggpubr::as_ggplot(
  cowplot::get_legend( hist_legend ) 
  ) + 
  theme(plot.margin = unit(c(0,0,0,0), "cm"))  ->  legend 
invisible(dev.off())
# < Legend::End   ####

# > Bar::Start ####
sorter <- function(df, col, de = T){
  do.call(
    "rbind",
    lapply(
      unique(df[, col]),
      function(x){
        data.frame(
          c = x,
          n = sum( df[grepl(x, df[, col]),'n'] ),
          stringsAsFactors = F
        )
      }
    )
  ) -> tmp_df
  
  return( tmp_df[order(tmp_df$n, decreasing = de),]$c )
}

readWithLevels <- function(f, col, lin, de = F){
  
  dat = read.csv( f, stringsAsFactors = F )
  
  linesLevels <- if (!is.null(lin)) rev(strsplit(lin, ",")[[1]]) else sorter(dat, col, de)
  
  dat[,col] <- factor(dat[,col], levels = linesLevels, ordered = T)
  
  return(dat[!is.na(dat[, col]),])
}

bardat = readWithLevels(opt$`barplot`, "region", opt$`lines`)

bardat$group <- factor(x = bardat$group,
                       levels = MajorGroups,
                       ordered = T )


ggplot( data = bardat, aes(x = region, y = -n, fill = group, order = group ) )+
  geom_bar(stat = "identity") +
  scale_fill_manual(values = fillcol) +
  coord_flip() +
  scale_y_continuous(labels = function(y) -y, expand = c(0,0) ) +
  scale_x_discrete( expand  = c(0,0) ) +
  labs(x = NULL, y = NULL) + 
  base_theme(type = "bar") +
  theme(plot.margin  = unit(c(0,0.15,0,0.15),"cm"))  ->   bar
# < Bar::End   ####

# > DumbBell::Start ####
spat = "^.+\\((.*)\\)[<>0-9]{0,}$"

DumbLevels  = attr(bardat$region, "levels")
# "Peru"     "Colombia" "Ecuador"  "Chile"   
BlockBreaks = attr(UpsetData$patternUsedPlusGroup, "levels")

do.call("rbind",
        lapply(
          BlockBreaks,
          function(x){
            tmpCo     = strsplit( gsub(spat, '\\1', x), "\\|")[[1]]
            tmpCo     = tmpCo[ match( DumbLevels, tmpCo, 0 ) ] 
            moreTmpCo = head( tmpCo[-1], -1)
      
            data.frame(
              trt   = x,
              l     = c( tmpCo[1]     , moreTmpCo ),
              r     = c( tail(tmpCo,1), moreTmpCo ),
              Group = gsub("^(.+)\\(.*", "\\1", x ),
              stringsAsFactors = F
              )
            }
          )
        ) -> DumbData

do.call("rbind",
        lapply(
          BlockBreaks,
          function(x){
            data.frame(x = DumbLevels, y = x, stringsAsFactors = F)
            }
          )
        ) -> DumbScatter

DumbData$l     <- factor(DumbData$l,     levels = DumbLevels,  ordered = T)
DumbData$Group <- factor(DumbData$Group, levels = MajorGroups, ordered = T)
DumbData$trt   <- factor(DumbData$trt,   levels = BlockBreaks, ordered = T)

DumbScatter$x <- factor(DumbScatter$x, levels = DumbLevels,  ordered = T)
DumbScatter$y <- factor(DumbScatter$y, levels = BlockBreaks, ordered = T)

strps = seq(DumbLevels)[seq(DumbLevels) %% 2 > 0]

ggplot() + 
  geom_point(data = DumbScatter,
             aes(x = x, y = y),
             size = opt$`pointsize`,
             color = "grey" ) + 
  geom_vline(xintercept = strps,
             color = "grey80", 
             size = 7, 
             alpha = 0.5) +
  geom_segment( data = DumbData,
                aes(y=trt, yend=trt, x=l, xend=r),
                lwd = 1) +
  geom_point(data = DumbData  ,aes(x = l, y = trt, color = Group), size = opt$`pointsize`)+
  geom_point(data = DumbData  ,aes(x = r, y = trt, color = Group), size = opt$`pointsize`) +
  scale_color_manual( values =  fillcol) + 
  coord_flip() +
  labs(y = NULL, x = NULL) +
  base_theme(type = "dumb")+
  theme(plot.margin = unit(c(0,0,0,0), "cm")) +
  scale_x_discrete( expand = c(0,0.45)) -> dumbbell
# < DumbBell::End   ####

# > CompilePlots:Start ####
ggplot() + theme_void() -> null
pdf(file = NULL)  # avoiding ggplot/cowplot bug
cowplot::plot_grid( null ,null
                    ,bar ,dumbbell
                    ,align       = "h"
                    ,rel_widths  = c(1,4)
                    ,rel_heights = c(2,1)
                    ,axis        = "tblr" ) -> upsethbind 
cowplot::plot_grid(legend ,hist
                   ,null  ,dumbbell
                   ,rel_widths  = c(1,4)
                   ,rel_heights = c(2,1)
                   ,align       = "v"
                   ,axis        = "tblr" ) ->  upsetvbind
invisible(dev.off())
jpeg(filename = opt$`output`, 
     width    = opt$`width`,
     height   = opt$`height`, 
     units    = 'in', 
     res      = opt$`resolution`)
cowplot::ggdraw(upsetvbind) + cowplot::draw_plot(upsethbind) 
invisible(dev.off())
# < CompilePlots:End   ####
