#!/usr/bin/Rscript

packs <- c("RCurl", "data.table",
           "dplyr", "ape",
           "optparse")

new.packs <- packs[!packs %in% installed.packages()[, 1]]

if( length(new.packs) == 0){

        writeLines("
                   Everything up-to-date
                   ")
        }else{
                for(i in 1:length(new.packs)){
                        writeLines(paste("\nInstalling:", new.packs[i], "\n"))

                        install.packages(new.packs[i],
                                         repos = "http://cran.us.r-project.org",
                                         dependencies = TRUE)
                }

                writeLines("
                           Everything up-to-date
                           ")
        }
