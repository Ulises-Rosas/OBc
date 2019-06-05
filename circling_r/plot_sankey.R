#!/usr/bin/env Rscript --vanilla

suppressWarnings({
  
  suppressMessages({
    
    library(ggplot2)
    library(optparse)
    library(RColorBrewer)
    library(DescTools)
    library(ggalluvial)
    library(ggrepel)
  })
})

# > ARGS[@] ####
option_list = list(
  
  make_option( 
    c("-i", "--input"),
    type="character",
    default=NULL,
    help="input file......................[default = %default]"
  ) ,
  make_option( 
    c("-p", "--palette"),
    type="character",
    default="RdYlBu",
    help="Palette of colors...............[Default = %default]"
  ),
  make_option( 
    c("-a", "--alpha"),
    type="numeric",
    default=0.9,
    help="Alpha value for flow............[Default = %default]"
  ),
  make_option( 
    c("-c", "--cols"),
    type="numeric",
    default=4,
    help="Number of columns..............[Default = %default]"
  ),
  make_option( 
    c("-b", "--basesize"),
    type="numeric",
    default=14,
    help="Size of labels.................[Default = %default]"
  ),
  make_option( 
    c("-n", "--notNA"),
    action = "store_false",
    default = T,
    help="not use NA......................[Default = %default]"
  ),
  make_option( 
    c("-N", "--nacolor"),
    type="character",
    default="darkgrey",
    help="Color for NAs stratums.........[Default = %default]"
  ),
  make_option( 
    c("-f", "--fillby"),
    type="character",
    default="OBIS",
    help="Color of links according to a given column....[Default = %default]"
  ),
  make_option( 
    c("-F", "--notfillstrat"),
    action = "store_false",
    default = T,
    help="Not use colors at `fillby` column..............[Default = %default]"
  ),
  make_option( 
    c("-k", "--keepNA"),
    action = "store_false",
    default = T,
    help="Keep NAs at `fillby` column..............[Default = %default]"
  ),
  make_option( 
    c("-g", "--gOrder"),
    type="character",
    default=NULL,
    help="Order of cols in CSV format..............[Default = %default]"
  ),
  make_option( 
    c("-t", "--transform"),
    type="character",
    default="none",
    help="Treat species counts. There are three options: 'log', 'squared' and 'cubic' [Default = %default]"
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

# print(opt)

# # > mockParams::Start ####
# opt = list()
# opt$`input` = "41139E5B90D34B"
# opt$`palette` = "RdYlBu"
# opt$`alpha` = 0.9
# opt$`cols` = 4
# opt$`basesize` = 14
# opt$`notNA` = T
# opt$`nacolor` = "darkgrey"
# opt$fillby = "OBIS"
# opt$`notfillstrat` = T
# opt$`keepNA` = T
# opt$`gOrder` = NULL
# opt$`transform` = "none" # "log", "squared", "cubic"
# # < mockParams::End   ####

# > loadData::Start ####
sortAxs <- function(gOrder, cols){

  if( is.null(gOrder) ){

    if ( cols == 2  )
      return(
        list(
          axs = c("Group", "Availability"),
          lims = c("OBIS", "BOLD")
        )
      )
    if( cols == 3)
      return(
        list(
          axs = c("Region", "Group", "Availability"),
          lims = c("Region", "OBIS", "BOLD")
        )
      )
    if( cols == 4 )
      return(
        list(
          axs = c("Region", "Group", "Availability2", "Distribution"),
          lims = c("Region", "OBIS", "BOLD", "Distribution")
        )
      )
  }else{

    gOrder = strsplit(gOrder, ",")[[1]]

    if (  length(gOrder) != cols )
      stop("Different vector size between given order and number of stratums")

    dOrder = c("Region", "OBIS", "BOLD","Distribution")
    avail  = ifelse(cols == 4, "Availability2", "Availability")
    axs    = c("Region", "Group", avail, "Distribution")

    names(axs) = dOrder
    return(
      list(
        axs  = as.character( axs[match(gOrder, dOrder, 0)] ) ,
        lims = gOrder
      )
    )
  }
}

stratLevels <- function(axs, df){

  return(
    as.character(
      unlist(
        sapply( axs, function(x) rev( levels(df[,x]) ) )
      )
    )
  )
}


if( opt$fillby == "Region"){
  fillFac  = fillName = "Region"

}else if( opt$fillby == "OBIS"){
  fillFac = "Group"
  fillName = "Taxonomical\ngroups"

}else if ( opt$fillby == "BOLD"){
  fillFac = ifelse(opt$cols == 3, "Availability", "Availability2")
  fillName = "Availability"

}else if ( opt$fillby == "Distribution"){
  fillFac = fillName = "Distribution"
  opt$cols = 4
}

df <- read.csv( file =  opt$input,
                stringsAsFactors = F,
                na.strings       = ifelse( opt$notNA, "", "NA" ) )

if(opt$transform == "none"){
  yLab = "Species"

}else if (opt$transform == "log"){
  df$Species = log10(df$Species)
  yLab = parse(text = "log[10](Species)")

}else if (opt$transform == "squared"){
  df$Species = df$Species**0.5
  yLab = parse(text = "(Species)^0.5")

}else if(opt$transform == "cubic"){
  df$Species = df$Species**(0.3)
  yLab = parse(text = "(Species)^0.3")
}

gsub("BOLD (.*)","\\1",df$Availability) -> df$Availability

threeLevels   = c("NA", "private","public outside","public inside")
fourAvailLevs = c("NA", "private", "public")
fourDistrLevs = c("NA", "outside", "inside")

factor(x = df$Region,
       levels  = unique(df$Region),
       ordered = T) -> df$Region

factor(x = df$Group,
       levels  = unique(df$Group),
       ordered = T) -> df$Group

factor(x = df$Availability,
       levels  = if (opt$notNA) threeLevels else tail(threeLevels, -1),
       ordered = T ) -> df$Availability

factor(x = df$Availability2,
       levels = if (opt$notNA) fourAvailLevs else tail(fourAvailLevs, -1),
       ordered = T)  -> df$Availability2

factor(x = df$Distribution,
       levels = if (opt$notNA) fourDistrLevs else tail(fourDistrLevs, -1),
       ordered = T) -> df$Distribution

if(opt$keepNA)
  df = df[!is.na(df[, fillFac]),]

if(opt$cols == 2){

  axs = sortAxs(gOrder = opt$gOrder, 2)

  ggplot(data = df,
         aes_string(
           axis1 = axs$axs[1],
           axis2 = axs$axs[2],
           y     = colnames(df)[6]
           )
         ) -> p

}else if (opt$cols == 3){

  axs = sortAxs(gOrder = opt$gOrder, 3)

  ggplot(data = df,
         aes_string(
           axis1 = axs$axs[1],
           axis2 = axs$axs[2],
           axis3 = axs$axs[3],
           y     = colnames(df)[6]
           )
         ) -> p

}else if (opt$cols == 4){

  axs = sortAxs(gOrder = opt$gOrder, 4)

  ggplot(data = df,
         aes_string(
           axis1 = axs$axs[1],
           axis2 = axs$axs[2],
           axis3 = axs$axs[3],
           axis4 = axs$axs[4],
           y     = colnames(df)[6]
           )
         ) -> p
}
stratumLevels = stratLevels(axs$axs, df)
lims = axs$lims
# df$Species = df$Species**0.5
# < loadData::End   ####

# > Colors::Start ####
suppressWarnings({
  cols1 = colorRampPalette( brewer.pal(12, opt$`palette`) )( length(  attr(df[, fillFac], "levels" )  ) )
})
fillcol   = DescTools::MixColor( col1 = "black", col2 = cols1,   amount1 = 0.3 )
bordercol = DescTools::MixColor( col1 = "white", col2 = fillcol, amount1 =  1 - opt$alpha )

# stratum cols
stratumcol        = rep("transparent", length(stratumLevels))
names(stratumcol) = stratumLevels

stratumcol[ names(stratumcol) == "NA"  ] <- opt$nacolor

if(opt$notfillstrat)
  stratumcol[match(levels(df[,fillFac]), names(stratumcol), 0)] <- bordercol
# stratum cols
# < Colors::End ####

# > ggplotThemeBase::Start ####
base_theme <- function(base_size = opt$`basesize`){
  theme_bw(base_size = base_size) %+replace%
    theme(
      panel.grid.minor = element_blank()
      ,panel.grid.major = element_blank()
      ,panel.border =  element_blank()
      ,plot.margin = unit(c(0,0,0,0),"cm")
      # ,legend.position = "top"
      ,axis.ticks.x.bottom = element_blank()
    )
  }
# < ggplotThemeBase::End   ####

# > Plot::Start ####
options(warn = -1)
q <- p +
  ggalluvial::geom_flow( aes_string(fill  = fillFac,
                                    color = fillFac),
                         lode.guidance = "leftright"
                         ,knot.pos     = 1/19
                         ,alpha        = opt$alpha
                         ,stat         = "alluvium"
                         ,size         = 0.04 ) +
  scale_fill_manual( values = bordercol,
                     name   = fillName,
                     na.translate = F ) +
  scale_color_manual( values = bordercol,
                      guide  = F ) +
  ggalluvial::geom_stratum( fill    = stratumcol
                            ,color  = "grey"
                            , na.rm = F ) +
  ggrepel::geom_text_repel( point.padding = NA,
                            label.strata  = TRUE,
                            stat          = "stratum" ) +
  scale_x_discrete( limits  = lims
                    ,expand = c(0, 0) ) +
  labs(y = yLab) +
  base_theme()
# options(warn = 0)
# < Plot::End   ####

## the more resolution,
#better are hidden border colours
jpeg(filename = opt$output,
     width    = opt$width,
     height   = opt$height,
     units    = 'in',
     res      = opt$resolution)
q
invisible(dev.off())

