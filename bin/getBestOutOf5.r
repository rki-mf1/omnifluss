#!/usr/bin/env Rscript

################### Note: This legacy code is not used anomore!
################### It was used when reference selection was done with Minimap2.

 #        #######    ###       #      ##### #     #
 #        #        #          # #    #       #   # 
 #        ###     #   ####   #####   #        # #  
 #        #        #    #   #     #  #         #   
 ######## #######   ####   #       #  #####    #   

###################
# Maintainer
#   @krannich479
# Author
#   @winterk
# Script:
#   Out of (up to 5) sequences, find the best reference sequence for one sample
# Input:
#   (1) Mapping stats (samtools coverage)   - TXT file with genome coverage, number of reads and mean depth
#   (2) Read depth stats (samtools depth)   - TSV file with read coverage per nucleotide to check the mapping uniformity
###################

if (!require(data.table)) {
  install.packages("data.table")
  library(data.table,setDTthreads(threads = 10))
}

if (!require(dplyr)) {
  install.packages("dplyr")
  library(dplyr, warn.conflicts = FALSE)
}

# Get input arguments from CLI
args = commandArgs(trailingOnly=TRUE)
#input_file <- args[1]
#output_path <- args[2]
coverage_txt <- args[1]
depth_tsv <- args[2]


##############################

get_my_final_ref <- function(coverage_txt, depth_tsv){
  #get list of the samples
  fileNames <- Sys.glob(paste0(sample_stats_files,"/*minimap.bamstats.txt"))
  big_stats_table <- NULL

  for(i in 1:length(fileNames)){
    #get segment name
    segment_name <- unlist(strsplit(basename(fileNames[i]), ".", fixed=TRUE))[1]
    #get sample name
    sample_name <- unlist(strsplit(basename(fileNames[i]), ".", fixed=TRUE))[2]
    #get the samtools coverage stats (its a summary file)
    segment_stats_summary <- fread(file=fileNames[i], header=TRUE)
    #remove empty mappings
    segment_stats_summary <- (segment_stats_summary[which(segment_stats_summary$numreads!=0),])
    
    #####check if the samples are empty
    if(nrow(segment_stats_summary) == 0 && file.size(paste0(dirname(fileNames[i]),"/", segment_name, ".", sample_name, ".minimap.bam_depth.txt")) == 0){
      #empty input empty output
      nix <- NULL
      write.table(nix, file=paste0(path_out, "/", segment_name , "_final_ref_", sample_name, ".txt"), quote=FALSE, row.names = FALSE, col.names = FALSE)
    }else{
      #####check if we have only one hit - if yes use it and move on
      if(nrow(segment_stats_summary) == 1){
        write.table(segment_stats_summary[1,1],file=paste0(path_out, "/", segment_name , "_final_ref_", sample_name, ".txt"), quote=FALSE, row.names = FALSE, col.names = FALSE)
        #prepare stats for summary file
        segment_stats_summary$x <- NA
        segment_stats_summary$variation  <- NA
        segment_stats_summary$znumberreads  <- NA
        segment_stats_summary$zvariation <- NA
        segment_stats_summary$zmeanmapq    <- NA
        segment_stats_summary$zcovbases   <- NA
        segment_stats_summary$magicnumber     <- NA
        segment_stats_summary$segment   <- segment_name
        big_stats_table <- rbind(big_stats_table,segment_stats_summary)
      }else{
        #get the read depth per position
        segment_read_depth <- fread(file=paste0(dirname(fileNames[i]),"/", segment_name, ".", sample_name, ".minimap.bam_depth.txt"), header=FALSE, sep ="\t" )
        
        #compute the read depth standard derivation per segment ==x
        segment_read_depth_sd <-aggregate(segment_read_depth$V3, list(segment_read_depth$V1), sd)
        #combine both data sets
        combined_segment_stats <- dplyr::right_join(segment_stats_summary, segment_read_depth_sd, by=c('#rname'='Group.1'))
        #calculate coefficient of variation (Standardabweichung / Mittelwert) pro segment
        #to be able to summarize and rank the different parameters I had to deivide the variation by 1 (I want a low variation but high read numbers)
        combined_segment_stats$variation <- 1/(combined_segment_stats$x/combined_segment_stats$meandepth)
        #calculate the z score per parameter column 
        #zscore: (parameter_value - parameter_value_mean)/sd
        combined_segment_stats$znumberreads <- (combined_segment_stats$numreads - mean(combined_segment_stats$numreads))/sd(combined_segment_stats$numreads)
        #values can't be 0 for sd calculation
        if(sd(combined_segment_stats$variation) != 0){
          combined_segment_stats$zvariation <- (combined_segment_stats$variation - mean(combined_segment_stats$variation))/sd(combined_segment_stats$variation)
        }else{combined_segment_stats$zvariation <- 0}
        if(sd(combined_segment_stats$meanmapq) != 0){
          combined_segment_stats$zmeanmapq <- (combined_segment_stats$meanmapq - mean(combined_segment_stats$meanmapq))/sd(combined_segment_stats$meanmapq)
        }else{combined_segment_stats$zmeanmapq <- 0}
        if(sd(combined_segment_stats$covbases) != 0){
          combined_segment_stats$zcovbases <- (combined_segment_stats$covbases - mean(combined_segment_stats$covbases))/sd(combined_segment_stats$covbases)
        }else{combined_segment_stats$zcovbases <- 0}
        
        #now compute a magic number to rank the references
        #I'm looking at the variation, the number of reads, mean mapping quality and the coverage
        #coverage is weighted 1x the other parameters 2x
        combined_segment_stats$magicnumber <- (2*combined_segment_stats$znumberreads + 2*combined_segment_stats$zvariation + combined_segment_stats$zcovbases + combined_segment_stats$zmeanmapq)/6
        #combined_segment_stats$magicnumber <- (2*combined_segment_stats$znumberreads + 2*combined_segment_stats$zvariation +  combined_segment_stats$zmeanmapq)/5
        
        #the reference with the highest magic number will be used
        #add segment column fo better filtering
        combined_segment_stats$segment <- segment_name
        top_hit_per_segment <- combined_segment_stats[which.max(combined_segment_stats$magicnumber),1]
        write.table(top_hit_per_segment,file=paste0(path_out, "/", segment_name , "_final_ref_", sample_name, ".txt"), quote=FALSE, row.names = FALSE, col.names = FALSE)
        
        big_stats_table <- rbind(big_stats_table,combined_segment_stats)
        
      } 
    }
  }
  #get the final list of references to use
  #final_ref_list <- big_stats_table %>% group_by(segment) %>% summarise(max_val = max(magicnumber), name = `#rname`[which.max(magicnumber)])
  #return results
  #write.table(as.data.frame(final_ref_list[3]),file=paste0(path_out, "/", "final_refs_", sample_name, ".txt"), quote=FALSE, row.names = FALSE, col.names = FALSE)
  write.table(big_stats_table,file=paste0(path_out, "/", "Ranking_top5_Refs_", sample_name, ".txt"), quote=FALSE, row.names = FALSE, col.names = TRUE)
}

get_my_final_ref(coverage_txt, depth_tsv)