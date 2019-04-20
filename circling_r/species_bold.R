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
  make_option(c("-p", "--prefix"), type="character",
              help="Prefix for output",
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

# opt$taxa = "Symbolophorus boops"
# opt = list()
# opt$taxa ="Symbolophorus boops"

taxon_search_url = "http://www.boldsystems.org/index.php/API_Tax/TaxonSearch?taxName="

taxon_search0 = opt$taxa %>% 
  gsub(" ", "%20", x = .) %>%
  paste(taxon_search_url, . ,sep = "") 
  
taxon_search1 = NULL

while(  is.null(taxon_search1) ){
  
  taxon_search1 = tryCatch(
    
    RCurl::getURL(taxon_search0),
    error = function(e){
      NULL
    }
  ) 
}

taxon_search =  gsub(".*\"total_matched_names\":([0-9]+)}", "\\1", x = taxon_search1)

if ( taxon_search == "1" ) {
  main_table = SpecimenData(taxon = opt$`taxa`)
  if( is.null( nrow( main_table ) ) ){
    
    paste(opt$`prefix`, opt$taxa, "private", sep = ",") %>% 
      writeLines(.)
  }else{

      main_table$country %>% 
      unique(.) %>% 
      paste(., collapse = "_") %>%
      paste(opt$`prefix`, opt$taxa, ., sep = ",") %>%
      writeLines(.)
  }
}else{
  
  paste(opt$`prefix`, opt$taxa, "unavailable", sep = ",") %>% 
    writeLines(.)
  
}