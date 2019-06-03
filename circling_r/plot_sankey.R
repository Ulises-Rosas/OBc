#!/usr/bin/env Rscript --vanilla

suppressWarnings({
  
  suppressMessages({
    
    library(ggplot2)
    library(optparse)
    library(RColorBrewer)
    library(DescTools)
    library(ggalluvial)
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
    c("-n", "--notNA"),
    action = "store_false",
    default = T,
    help="not use NA......................[Default = %default]"
  )
  
)

opt_parser = OptionParser(option_list = option_list, description = "")
opt = parse_args(opt_parser)
# < ARGS[@] ####

# print(opt)

# > mockParams::Start ####
opt = list()
opt$`input` = "41139E5B90D34B"
opt$`palette` = "RdYlBu"
opt$`alpha` = 0.9
opt$`cols` = 4
opt$`basesize` = 15
opt$`notNA` = T
opt$`nacolor` = "darkgrey"
opt$`fill` = "OBIS"
opt$`colstratum` = T
opt$`adjustFill` = T
# < mockParams::End   ####

# > loadData::Start ####
if(opt$`fill` == "Region"){
  fillFac = "Region"
  
  }else if( opt$fill == "OBIS"){
    fillFac = "Group"
    
    }else if (opt$fill == "BOLD"){
      fillFac = ifelse(opt$cols == 3, "Availability", "Availability2")
      
      }else if (opt$fill == "Distribution"){
        fillFac = "Distribution"
        opt$cols = 4
        }

df <- read.csv(
  file =  opt$input,
  stringsAsFactors = F,
  na.strings       = ifelse( opt$notNA, "", "NA" )
  )

df$Region <- factor(x       = df$Region,
                    levels  = unique(df$Region),
                    ordered = T)

df$Group <- factor(x       = df$Group,
                   levels  = unique(df$Group),
                   ordered = T)

preStratumLevels = c( rev(attr(df$Region, "levels")), rev(attr(df$Group, "levels") ))

if(opt$cols == 3){

  gsub("BOLD (.*)","\\1",df$Availability) -> df$Availability 
  
  threeLevels =  c("NA", "private","public outside","public inside")

  factor(x = df$Availability,
         levels  = if (opt$notNA) threeLevels else tail(threeLevels,-1),
         ordered = T ) -> df$Availability 
  
  if(opt$adjustFill)
    df = df[!is.na(df[, fillFac]),]
  
  ggplot(data = df,
         aes_string(
           axis1 = colnames(df)[1],
           axis2 = colnames(df)[2],
           axis3 = colnames(df)[3],
           y     = colnames(df)[6]
           )
         ) -> p 
  
  stratumLevels = c(preStratumLevels,  rev(attr(df$Availability, "levels") ))
  
  lims = c("Region" , "OBIS", "BOLD")
  
}else if (opt$cols == 4){
  
  options(warn = -1)
  
  fourAvailLevs = c("NA", "private", "public")
  fourDistrLevs = c("NA", "outside", "inside")

  factor(x = df$Availability2,
         levels = if (opt$notNA) fourAvailLevs else tail(fourAvailLevs, -1),
         ordered = T)  -> df$Availability2 
  
  factor(x = df$Distribution,
         levels = if (opt$notNA) fourDistrLevs else tail(fourDistrLevs, -1),
         ordered = T) -> df$Distribution 
  
  if(opt$adjustFill)
    df = df[!is.na(df[, fillFac]),]
  
  ggplot(data = df,
         aes_string(
           axis1 = colnames(df)[1],
           axis2 = colnames(df)[2],
           axis3 = colnames(df)[4],
           axis4 = colnames(df)[5]
           ,y    = colnames(df)[6]
           )
         ) -> p 
  
  stratumLevels = c( preStratumLevels, rev(attr(df$Availability2, "levels")), rev(attr(df$Distribution, "levels") ))
  
  lims = c("Region" , "OBIS" , "BOLD" , "Distribution")
}

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

if(opt$colstratum)
  stratumcol[match(attr(df[, fillFac], "levels" ), names(stratumcol), 0)] <- bordercol
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

q <-  p +
  ggalluvial::geom_flow( aes_string(fill  = fillFac,
                                    color = fillFac),
                         lode.guidance = "leftright"
                         ,knot.pos     = 1/19
                         ,alpha        = opt$alpha
                         ,stat         = "alluvium"
                         ,size         = 0.04 ) +
  scale_fill_manual( values = fillcol,
                     name   = "Taxonomical\ngroups", 
                     na.translate = F ) +
  scale_color_manual(values = bordercol,
                     guide  = F ) +
  ggalluvial::geom_stratum( fill    = stratumcol
                            ,color  = "grey"
                            , na.rm = F ) +
  ggrepel::geom_text_repel( point.padding = NA,
                            label.strata  = TRUE,
                            stat          = "stratum" ) +
  scale_x_discrete( limits = lims ,
                    expand = c(0, 0) ) +
  base_theme()

## the more resolution,
#better are hidden border colours
jpeg(filename = "testSankey.jpeg",
     width    = 12.5,
     height   = 4.25,
     units    = 'in',
     res      = 500)
q
dev.off()

