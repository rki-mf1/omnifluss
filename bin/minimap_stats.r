#!/usr/bin/env Rscript

###################
# Maintainer
#   @krannich479
# Author
#   @winterk
# Script:
#   Read a sample's minimap2 PAF file (sample-segmentDB alignment) and return the five best references in terms of number of residue matches
###################

library(data.table)
setDTthreads(threads = 10)

# I/O
args = commandArgs(trailingOnly=TRUE)
sample_in <- args[1]

# function to read PAF
read_minimap_output <- function(sample){
    #extract sample names
    sampleName <- gsub (".minimap.paf", "", basename(sample))
    #heck if the samples are empty, if yes return NA if nonempty return first hit
    if(file.size(sample) > 0){
      minimap_output <- fread(file=sample, header=FALSE, select=c(6,10), sep= "\t", fill=TRUE)
      #V6 Target sequence name
      #V10 Number of residue matches
      #collapse duplicated references and sum up the matching residues
      Ref_freq_matches<- aggregate(minimap_output$V10 ~ minimap_output$V6, data=minimap_output, FUN=sum)
      #order by matching residues
      ordered_Ref_freq_matches <- Ref_freq_matches[order(Ref_freq_matches[,2], decreasing = TRUE),]
      #if else in case we don't get 5 hit Refs
      if(nrow(ordered_Ref_freq_matches) >= 5){
        best_ref <-ordered_Ref_freq_matches[1:5,1]
      } else{
        best_ref <-ordered_Ref_freq_matches[1:nrow(ordered_Ref_freq_matches),1]
      }
      write.table(best_ref,file=paste0(sampleName, "_best_refs.txt"), quote=FALSE, row.names = FALSE, col.names = FALSE)
    } else {
      best_ref <- NULL
      write.table(best_ref,file=paste0(sampleName, "_best_refs.txt"), quote=FALSE, row.names = FALSE, col.names = FALSE)
    }
}

if (args[1] == "--version"){
  cat("0.1.1\n")
} else {
  read_minimap_output(sample_in)
}
