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
  #make_option(c("-g", "--area-name"), type="character",
  #            help="Geographical area for downloading species",
  #            metavar="character"),
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

#opt$taxa = "Chelonia mydas"
#opt$taxa ="Schizodon jacuiensis"

taxon_search_url = "http://www.boldsystems.org/index.php/API_Tax/TaxonSearch?taxName="

taxon_search = opt$taxa %>% 
  gsub(" ", "%20", x = .) %>%
  paste(taxon_search_url, . ,sep = "") %>%
  RCurl::getURL(.) %>% 
  gsub(".*\"total_matched_names\":([0-9]+)}", "\\1", x = .)
  
if ( taxon_search == "1" ) {
  main_table = SpecimenData(taxon = opt$`taxa`)
  if( is.null( nrow( main_table ) ) ){
    
    paste(opt$taxa, "private", sep = ",") %>% 
      writeLines(.)
  }else{

      main_table$country %>% 
      unique(.) %>% 
      paste(., collapse = "_") %>%
      paste(opt$taxa, ., sep = ",") %>%
      writeLines(.)
  }
}else{
  
  paste(opt$taxa, "unavailable", sep = ",") %>% 
    writeLines(.)
  
}