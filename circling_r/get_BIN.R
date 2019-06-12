#!/usr/bin/env Rscript --vanilla

OBC_PREFIX="/Users/admin/Desktop/Circulo/OBc"

suppressWarnings({
  
  suppressMessages({
    
    library(optparse)
    source( paste0(OBC_PREFIX,"/circling_r/AuditionBarcode.v.2.R") )
    source( paste0(OBC_PREFIX,"/circling_r/SpecimenData.R") )
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
    c("-q", "--quiet"),
    action = "store_false",
    default = T,
    help="If selected, toolbar is not shown...[Default = %default]"
  ),
  make_option( 
    c("-o", "--output"),
    type="character",
    default="saved_bold.tsv",
    help="output file.....................[default = <%default>]"
  )
)

opt_parser = OptionParser(option_list = option_list, description = "")
opt = parse_args(opt_parser)
# < ARGS[@]::End    ####

# print(opt)

# > mock params ####
# opt = list()
# opt$quiet = TRUE
# opt$input = "23838E9EED1346"
# opt$output = "bold_audited.tsv"
# < mock params ####

readUniqueSpps <- function(f){

  read.table( f, TRUE, "\t", stringsAsFactors = F) -> d0
  d0[ !duplicated(d0$Species), ] -> d1
  return( d1 )
}
hasData   <- function(s) {
  
  # s = "Alopias pelagicus"
  d <- NULL
  while( is.null(f))
    d <- tryCatch({SpecimenData(s)}, error = function(e) NULL)
  
  !is.null(nrow(d)) && nrow(d) > 0 
}
# auditData <- function(o,d,s) rbind( o, data.frame(d, AuditionBarcodes(s)) )
auditData <- function(d,s) data.frame(d, AuditionBarcodes(s)) 
clp   <- function(c,n) paste( rep(c,n), collapse = "")
wstdo <- function(f,m,s1,s2,p,s) cat( sprintf(f,m,s1,s2,p,s), file = stdout() )


df = readUniqueSpps(opt$input)

w   = 50
f   = "\r%40s: [%s%s] (%6.2f %%) %s"
out = data.frame()

for(x in unique(df$Group)){

  g_df = df[df$Group == x,]
  n    = nrow(g_df)

  for(i in 1:n){
    # species line
    l = g_df[i,]
    
    if(opt$quiet){
      # prop
      p = i/n
      # int prop
      ip = round(p * w, 0)
      # init message
      m  = paste0('Getting BINs in ', x)
      
      wstdo(f, m, clp("#", ip), clp("-", w - ip), p * 100, l$Species)
    }
    if( hasData( l$Species ) ){
      
      p <- NULL
      while( is.null(p) ){
        p <- tryCatch( { auditData(l, l$Species) }, error = function(e) NULL )
      }
      rbind(out, p) -> out
    }
  }
  cat("\n")
}

write.table(x = out, file = opt$output, sep = "\t", quote = F, row.names = F)
