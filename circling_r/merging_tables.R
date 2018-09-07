suppressMessages({
  
  library(data.table)
  library(dplyr)
  library(ape)
  library(RCurl)
  library(optparse)
})

option_list = list(
  
  make_option(c("-b", "--original-bold"), type="character",
              default=NULL,
              help="Table of original names retrieved from BOLD",
              metavar="character"),
  make_option(c("-v", "--validated-bold"), type="character",
              default=NULL,
              help="Table of validated names of original names from BOLD",
              metavar="character"),
  make_option(c("-o", "--validated-obis"), type="character",
              default=NULL,
              help="Table of validated names of original names from OBIS",
              metavar="character"),
  make_option(c("-f", "--output-name"), type="character",
              default="Merged_table",
              help="Output name",
              metavar="character")
)

opt_parser = OptionParser(option_list=option_list, description = "
        Merging tables of validated names from BOLD with validated names from OBIS
                          ")

opt = parse_args(opt_parser)

if ( is.null(opt$`original-bold`) || is.null(opt$`validated-bold`) || is.null(opt$`validated-obis`) ){
  
  print_help(opt_parser)
  stop("Complete set of tables must be supplied.\n", call.=FALSE)
  
}

original_bold   =  fread(opt$`original-bold`, sep = "\n", header = F)$V1
validated_bold  =  fread(opt$`validated-bold`, sep = "\n", header = F)$V1
validated_obis  =  fread(opt$`validated-obis`, sep = "\n", header = F)$V1

data.frame(original_bold , validated_bold) %>% 
  .[.$validated_bold  %in% validated_obis,] %>%
  write.table(., file = opt$`output-name`,
              quote = F, row.names = F, col.names = T, sep = ",")
  
  