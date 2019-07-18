#!/usr/bin/env Rscript --vanilla

suppressWarnings({
  
  suppressMessages({
    
    library(ggplot2)
    library(optparse)
    library(RColorBrewer)
    library(cowplot)
    library(viridis)
    # library(viridisLite)
  })
})

# > ARGS[@] ####
option_list = list(
  
  make_option( 
    c("-a", "--audited"),
    type="character",
    default=NULL,
    help="audited data frame............[default = %default]"
  ),
  make_option( 
    c("-i", "--indication"),
    type="character",
    default=NULL,
    help="indication of taxa...............[default = %default]"
  ),
  make_option( 
    c("-g", "--grades"),
    type="character",
    default=NULL,
    help="grades levels...............[default = %default]"
  ),
  make_option( 
    c("-H", "--height"),
    type="numeric",
    default=4.5,
    help="Height of plot..................[Default = %default]"
  ),
  make_option( 
    c("-W", "--width"),
    type="numeric",
    default=12.5,
    help="Width of plot...................[Default = %default]"
  ),
  make_option( 
    c("-r", "--resolution"),
    type="numeric",
    default=200,
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
# < ARGS[@] ####

## mock params
# opt = list()
# opt$audited = "bold_auditedWithRanks.tsv"
# opt$indication = "796E7A4D206642"
# opt$output = "RadarPolygon_AllPercentage.tiff"
# opt$height = 7
# opt$width = 14
# opt$resolution = 250
# opt$grades = "A/B,C/D,E*/E**"
## mock params

groupByTax <- function(data, fac, freq = F){
  
  tmp_indexer = unique(data[,fac])
  
  do.call(
    'rbind',
    lapply(
      tmp_indexer,
      function(x){
        tmp_df = data[ grepl(x, data[,fac]) , ]
        tmp_table = table(tmp_df$Classification)
        if(freq){
          data.frame( tax  = x, 
                      var  = names(tmp_table),
                      per = as.numeric(tmp_table) )
        }else{
          data.frame( tax  = x, 
                      var  = names(tmp_table),
                      per = as.numeric(tmp_table*100/sum(tmp_table)) )
        }
      })
  ) -> out
  
  return(out)
}

radarPolygon <- function(df, 
                         MajorGroup, 
                         taxonomicalRank, 
                         legend = T,  
                         pal = NA,
                         select = 5,
                         whole = F ,
                         transform = "percentage", 
                         transformNumber = 0.5,
                         changeTitle = T,
                         basesize = 14, 
                         linesize = 1.8){
  ### delete
  # MajorGroup = "Invertebrate"
  # taxonomicalRank = 'Group'
  ### delete
  
  pereval <- transform == "percentage"
  df <- df[df$Group == MajorGroup,]
  
  if(nrow(df) == 0)
    return(NULL)
  
  gLevs = strsplit(opt$grades, split = ",")[[1]]

  factor(
    df$Classification,
    levels  = gLevs,
    ordered = T
  ) -> df$Classification
  
  if (whole) {
    
    tmp_table = table(df$Classification)
    
    data.frame(
      var = names(tmp_table),
      per = as.numeric(tmp_table),
      tax = taxonomicalRank
    ) -> df2
    
    legend     = F
    MajorGroup = ifelse(changeTitle,
                        paste0(MajorGroup, ": All"),
                        MajorGroup)
  }else{
    
    if( !is.na( select ) ){
      do.call(
        "rbind",
        lapply(
          unique(df[,taxonomicalRank]),
          function(x){
            n = nrow(df[grepl(x,df[,taxonomicalRank]),])
            data.frame(tax = x, n, stringsAsFactors = F)
          })
        ) -> tmp0
      tmp0[order(tmp0$n, decreasing = T),] -> tmp
      
      if ( select <= nrow(tmp) && select >= 1 ){
        paste0("(",
               paste0(
                 tmp$tax[1:select],
                 collapse = "|"),
               ")") -> pat
        
        df[grepl(pat, df[,taxonomicalRank]),] -> df
        
        factor(x = df[,taxonomicalRank],
               levels  = tmp$tax,
               ordered = T) -> df[,taxonomicalRank]
      }
    }
    
    groupByTax(df,taxonomicalRank, freq = ifelse(pereval, F, T) ) -> df2
    df2 = df2[order(df2$var),]
  }
  
  if (transform == "exponential"){
    df2$per <- df2$per**transformNumber
    
  }else if(transform == "log"){
    if( any(df2$per == 0) ) df2$per <- df2$per + 1
    
    df2$per <- log(df2$per, transformNumber)
    
  }else if( pereval ){
    if( whole ) df2$per <- df2$per*100/sum(df2$per)
    
  }
  
  ### strips chunk {start}
  do.call(
    'rbind',
    lapply(
      unique(df2$var),
      function(x){
        data.frame(
          var = x,
          n = max(df2[df2$var == x,'per']),
          stringsAsFactors = F
        )
      })
    ) -> textBar
  
  textBar = textBar[order(textBar$n, decreasing = T),]
  textBarMax = textBar$n[1]
  
  step = round(textBarMax/4, digits = 0)
  strp = seq(0, textBarMax, ifelse(step == 0, 1, step) )
  ind  = seq_along(strp) %% 2 == 1
  ### strips chunk {end}
  
  yintervalues = c(0, strp[ if ( tail( ind, 1 ) ) ind else !ind ])
  
  list(
    ggplot2::geom_hline( yintercept = yintervalues, lwd = 0.5, lty = 5, color = "grey80"),
    ggplot2::geom_text( data    = data.frame( x = 1, y = yintervalues ),
                        mapping = aes( x = x, y = y, label = if (pereval) paste0( y, "%" ) else y ),
                        hjust   = 1)
  ) -> annotHlines
  
  
  if( length( unique( df2$tax ) ) == 1  ){
    rbind(
      df2,
      data.frame(tax = 'mock',
                 var = df2$var,
                 per = df2$per,
                 stringsAsFactors = F)
    ) -> df2 
    
    df2 = df2[order(df2$var), ]
  }
    
  
  p <- ggplot() +
    geom_polygon(df2, 
                 mapping = aes(var, per, group=tax, col=tax),
                 size=linesize
                 , fill = NA
                 , show.legend = ifelse(legend, T, F)) +
    scale_y_continuous(expand =  c( 0.09, 1 ) ) +
    labs(y     = NULL,
         x     = NULL,
         title = ifelse(
           !legend && !whole && changeTitle,
           paste0( MajorGroup, ": ", taxonomicalRank),
           MajorGroup )
    ) +
    annotHlines +
    coord_polar(theta = "x", start = -pi/length(gLevs)) +
    theme_bw(base_size = basesize)+
    theme(panel.grid.minor = element_blank()
          ,panel.background = element_blank()
          ,panel.grid.major.y = element_blank()
          ,panel.grid.major.x = element_line(color = "grey50", linetype = 3)
          ,panel.border = element_blank()
          ,axis.text.y = element_blank()
          ,axis.ticks.y = element_blank()
          ,plot.margin = unit( c(0,0,0,0), "in" ))
  
  if( any( df2$tax == "mock" ) ){
    
    if (whole){
      p <- p + 
        scale_color_manual(values = c("black", "transparent")) +
        theme(plot.margin = unit(c(0,0,0,0), "cm"))
      
    }else{
      p <- p +
        scale_color_manual(values = c("black", "transparent"),  
                           name   = taxonomicalRank,
                           labels = c(grep("mock", unique(df2$tax), value = T, invert = T), "") ) +
        theme(plot.margin = unit(c(0,0,0,0), "cm"))
    }
  }else{
    
    if( is.na(pal) ){
      cols1 <- viridis(length(unique(df2$tax)))
      p <- p + 
        scale_color_manual(values = cols1, name = taxonomicalRank)+
        theme(plot.margin = unit(c(0,0,0,0), "cm"))
      
    }else{
      cols1 <- colorRampPalette(brewer.pal( 5, pal))(length(unique(df2$tax)))
      p <- p + 
        scale_color_manual(values = cols1, name = taxonomicalRank) +
        theme(plot.margin = unit(c(0,0,0,0), "cm"))
    }
  }
  return(p)
}

df = read.table(opt$audited, header = T, sep = "\t",stringsAsFactors = F)
params = read.csv(opt$indication, stringsAsFactors = F)

lapply(
  1:nrow(params),
  function(x){
    # x = 1
    tmp = params[x,]
    radarPolygon(
      df = df,
      MajorGroup = tmp$MajorGroup,
      taxonomicalRank = tmp$taxonomicalRank, 
      legend = tmp$legend, 
      pal = tmp$pal,
      select = tmp$select,
      whole = tmp$whole,
      transform = tmp$transform,
      transformNumber = tmp$tnumber, 
      changeTitle = tmp$ctitle,
      basesize = tmp$labelsize, 
      linesize = tmp$linesize
    )
  }
) -> out

out = Filter(Negate(is.null), out)

if(length(out) == 0)
  stop("Error: Nothing to plot")

jpeg(filename = opt$output,
     width = opt$width, 
     height = opt$height, 
     units = 'in', 
     res = opt$res)
cowplot::plot_grid(plotlist = out)
invisible(dev.off())

