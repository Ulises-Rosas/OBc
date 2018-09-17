#!/usr/bin/Rscript

suppressMessages({
  
  library(data.table)
  library(dplyr)
  library(ape)
  library(RCurl)
  library(optparse)
})

option_list = list(
  
  make_option(c("-t", "--taxa"), type="character",
              default=NULL,
              help="Target taxa",
              metavar="character"),
  make_option(c("-g", "--area-name"), type="character",
              help="Geographical area for downloading species",
              metavar="character"),
  make_option(c("-o", "--output-name"), type="character",
              help="Output name",
              metavar="character")
  
)

opt_parser = OptionParser(option_list=option_list, description = "
                          Check list retrieved from BOLD
                          ")

opt = parse_args(opt_parser)

if ( is.null(opt$`taxa`) ){
  
  print_help(opt_parser)
  stop("--taxa argument must be supplied.\n", call.=FALSE)
  
}

SpecimenData <- function(taxon, ids, bin, container,
                         institutions, researchers, geo, ...){
  input <- data.frame(
    names = names(as.list(environment())),
    args = sapply(as.list(environment()), paste),
    stringsAsFactors = F
  )
  
  #text <- RCurl::getURL(
  URLtxt <- paste(if(list(...)[1] == "only"){
    "http://www.boldsystems.org/index.php/API_Public/sequence?"}
    else{if(list(...)[1] == "combined"){
      "http://www.boldsystems.org/index.php/API_Public/combined?"}
      else{
        "http://www.boldsystems.org/index.php/API_Public/specimen?"}
    },
    paste(
      paste(input[!(input$args == ""),]$names,
            "=",
            sapply(input[!(input$args == ""),]$args, function(x){
              if(length(strsplit(x, " ")[[1]]) > 1){
                paste(gsub(" ", "%20", x), "&", sep = "")
              }else{paste(x, "&", sep = "")}}
            ),
            sep = ""),
      collapse = ""),
    "format=tsv",
    sep = "")
  text <- RCurl::getURL(URLtxt)
  
  if(list(...)[1] == "only")
    return(ape::read.FASTA(textConnection(text)))
  
  if(text == "")
    return(text)
  
  data.table::fread(text)
  
}



main_table = SpecimenData(taxon = opt$`taxa`, geo = opt$`area-name`)

if(is.null( nrow(main_table) ) ){
  
  write.table(NULL, file = opt$`output-name`, quote = F,row.names = F, col.names = F)
  }else{
    
    main_table$species_name %>% 
      unique(.) %>% lapply(., function(x){
        if (grepl("[A-Z][a-z]+ [a-z]+$", x) && 
            !grepl("[A-Z][a-z]+ sp[p|\\.]{0,2}$", x) &&
            !grepl("[A-Z][a-z]+ cf\\. .*", x) ){
          return(x)
          }
        }) %>% 
      unlist(.) %>% 
      write.table(., file = opt$`output-name`, quote = F,row.names = F, col.names = F)
  }
  