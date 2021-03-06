#Julian Ramirez-Villegas, Ulrike Rippke and Louis Parker
#CIAT / CCAFS / UoL
#May 2014
stop("!")

#gains in suitable area

#load needed libraries
library(raster); library(maptools); library(rasterVis); data(wrld_simpl)

####
#maps: of time of crossing
#1. loop running decades to calculate frequency of crossing each threshold
#2. from these calculate:
#   *time1: 0-2 years below threshold
#   *time2: 3-5 years below threshold
#   *time3: more than 5 years below threshold
#3. use these to determine date of crossing
#4. calculate minimum and maximum crossing amongst all GCMs
#5. plot minimum, maximum and ensemble mean

#i/o directories
#mbp at CIAT
#b_dir <- "/nfs/workspace_cluster_6/VULNERABILITY_ANALYSIS_CC_SAM/ECOCROP_DEVELOPMENT_CC_SAM/ULI/Uli_modelling"
#base_run <- paste(b_dir,"/CRU_30min_1971-2000_af/analyses/cru_select_corNames",sep="")

#mbp at CIAT
dataset <- "cru"
b_dir <- "/nfs/workspace_cluster_6/VULNERABILITY_ANALYSIS_CC_SAM/ECOCROP_DEVELOPMENT_CC_SAM/modelling/Cul_de_sacs"
base_run <- paste(b_dir,"/model_runs/",dataset,"_hist",sep="")

#output directories
#out_dir <- "~/Google Drive/papers/transformational-adaptation" #mbp
out_dir <- paste(b_dir,"/analysis_outputs",sep="") #mbp
fig_dir <- paste(out_dir,"/figures_",dataset,sep="")
dfil_dir <- paste(out_dir,"/data_files_",dataset,sep="")

#rcp input dir
rcp <- "rcp85" #rcp60 rcp85
rcp_run <- paste(b_dir,"/model_runs/",dataset,"_futclim_bc/",rcp,sep="")

#read in thresholds and crop names
thresh_val <- read.csv(paste(b_dir,"/model_data/thresholds.csv", sep=""))
thresh_val <- thresh_val[which(thresh_val$dataset == dataset),]
thresh_val <- thresh_val[c(1:3,10:13,15:16),]
thresh_val$dataset <- NULL; row.names(thresh_val) <- 1:nrow(thresh_val)
thresh_val$AUC <- thresh_val$MinROCdist <- thresh_val$MaxKappa <- NULL
names(thresh_val)[2] <- "value"
thresh_val$value <- thresh_val$value * 100
thresh_val$crop[which(thresh_val$crop == "fmillet_EAF_SAF")] <- "fmillet"
thresh_val$crop[which(thresh_val$crop == "yam_WAF")] <- "yam"
thresh_val$crop <- paste(thresh_val$crop)

#load baseline suitability rasters
base_stk <- stack(paste(base_run,"/",thresh_val$crop,"_suit.tif",sep=""))
names(base_stk) <- paste(thresh_val$crop)

#list of GCMs
gcm_list <- list.files(rcp_run)

#list of years and decades
yr_list <- c(2006:2098)
dc_list <- c((min(yr_list)+10):(max(yr_list)-9))

#loop through crops
for (i in 1:nrow(thresh_val)) {
  #i <- 1
  crop_name <- paste(thresh_val$crop[i])
  thr <- thresh_val$value[i]
  cat("\n...processing crop=",crop_name,"\n")
  
  #folder of dfil_dir per crop
  dfil_crop <- paste(dfil_dir,"/",crop_name,sep="")
  
  #extract data from baseline raster
  xy_allb <- as.data.frame(xyFromCell(base_stk[[crop_name]], 1:ncell(base_stk[[crop_name]])))
  xy_allb$base <- extract(base_stk[[crop_name]], xy_allb[,c("x","y")])
  
  #loop through GCMs
  for (gcm in gcm_list) {
    #gcm <- gcm_list[1]
    cat("...processing gcm=",gcm,"\n")
    
    if (!file.exists(paste(dfil_crop,"/crossinverse_",rcp,"_",gcm,".RData",sep=""))) {
      #raster stack with all years
      yr_stk <- stack(paste(rcp_run,"/",gcm,"/r1i1p1/",yr_list,"/",crop_name,"_suit.tif",sep=""))
      
      #loop decades
      dc_out_stk <- c()
      for (dc in dc_list) {
        #dc <- dc_list[1]
        cat("...processing decade=",dc,"\n")
        
        dc_stk <- yr_stk[[(dc-10-2005):(dc+10-2006)]]
        
        #extract decade data
        xy_all <- cbind(xy_allb, as.data.frame(extract(dc_stk, xy_allb[,c("x","y")])))
        
        #function to calculate frequency of crossing
        calc_freq <- function(x, thr) {
          #x <- as.numeric(xy_all[9941,3:ncol(xy_all)])
          x_b <- x[1]
          x_d <- x[2:length(x)]
          if (is.na(x_b)) { #if pixel value is NA in baseline then NA (outside land areas)
            y <- NA
          } else if (x_b == 0 | x_b < thr) { #if baseline == 0 (unsuitable) then perform calculation
            y <- length(which(x_d < thr))
          } else { #if not below threshold then return -1
            y <- NA #length(which(x_d < thr))
          }
          return(y)
        }
        
        #run calculation for all grid cells
        xy_all$freq <- apply(xy_all[,3:ncol(xy_all)], 1, FUN=calc_freq, thr)
        
        #put into raster
        rs_freq <- raster(dc_stk)
        rs_freq[cellFromXY(rs_freq, xy_all[,c("x","y")])] <- xy_all$freq
        
        #append to raster stack
        dc_out_stk <- c(dc_out_stk, rs_freq)
      }
      dc_out_stk <- stack(dc_out_stk)
      names(dc_out_stk) <- paste("dec.",dc_list,sep="")
      
      ###
      #calculate decade of interest:
      #*time2: 10 or less years with frequency of crossing
      
      #function to calculate decade
      calc_ctime <- function(x) {
        #x <- as.numeric(xy_all[10751,3:ncol(xy_all)])
        #x <- as.numeric(xy_all[10750,3:ncol(xy_all)])
        #plot(x,ty="l")
        if (is.na(x[1])) { #pixel is orignally NA
          y <- NA
        } else if (length(which(x == 20)) == length(x)) { #pixel equals 20 (meaning it was always below threshold), thus in fact never crosses
          y <- 99 #length(dc_list)+1 #i.e. no gain (redundant with length(x<=10) eq. 0 below)
        } else {
          #1. if there are no periods < 10 then we return 99
          #2. else we return first date of cross
          if (length(which(x < 10)) == 0) {
            y <- 99 #length(dc_list)+1 #doesn't cross in analysis period
          } else if (length(which(x > 10)) > 0) {
            y <- max(which(x > 10))+1 #crosses and stays below
          } else if (length(which(x < 10)) == length(x)) {
            y <- 0 #gained is now --meaning there is some error involved in baseline thresholding
          }
        }
        return(y)
      }
      
      #value NA is NA or suitable in baseline
      #value >= 0 is actual frequency
      xy_all <- as.data.frame(xyFromCell(dc_out_stk, 1:ncell(dc_out_stk)))
      xy_all <- cbind(xy_all, as.data.frame(extract(dc_out_stk, xy_all[,c("x","y")])))
      
      #run calculation for all grid cells
      cross_stk <- c()
      adaptype <- 2
      cat("...calculating positive adaptation time=",adaptype,"\n")
      xy_all$crossval <- apply(xy_all[,grep("dec.",names(xy_all))], 1, FUN=calc_ctime)
      crosstime_val <- data.frame(crossval=1:length(dc_list), crosstime=dc_list)
      crosstime_val <- rbind(crosstime_val,c(0,2015))
      crosstime_val <- rbind(crosstime_val,c(99,(max(dc_list)+1)))
      crosstime_val <- rbind(crosstime_val,c(NA,NA))
      xy_all <- merge(xy_all, crosstime_val, by="crossval", all.x=T, all.y=F)
      names(xy_all)[ncol(xy_all)] <- paste("crosstime",adaptype,sep="")
      
      #create raster
      rs_cross <- raster(dc_out_stk)
      rs_cross[cellFromXY(rs_cross, xy_all[,c("x","y")])] <- xy_all[,paste("crosstime",adaptype,sep="")]
      
      #append into rasterStack
      cross_stk <- rs_cross
      
      #save this model output
      save(list=c("dc_out_stk","cross_stk"), file=paste(dfil_crop,"/crossinverse_",rcp,"_",gcm,".RData",sep=""))
    } else {
      load(file=paste(dfil_crop,"/crossinverse_",rcp,"_",gcm,".RData",sep=""))
    }
  }
}


####
#load all GCMs for each crop and:
#4. calculate minimum and maximum crossing amongst all GCMs
#5. plot minimum, maximum and ensemble mean

###
#function to plot maps
rs_levplot2 <- function(rsin,zn,zx,nb,brks=NA,scale="YlOrRd",ncol=9,col_i="#CCECE6",col_f="#00441B",rev=F,leg=T,colours=NA) {
  if (scale %in% row.names(brewer.pal.info)) {
    pal <- rev(brewer.pal(ncol, scale))
    if (!is.na(colours[1])) {pal <- colours}
  } else {
    pal <- colorRampPalette(c(col_i,col_f))(ncol)
    if (!is.na(colours[1])) {pal <- colours}
  }
  if (rev) {pal <- rev(pal)}
  pal <- c("grey 30",pal,"grey 80")
  
  if (is.na(brks[1])) {brks <- do.breaks(c(zn,zx),nb)}
  
  #set theme
  this_theme <- custom.theme(fill = pal, region = pal,
                             bg = "white", fg = "grey20", pch = 14)
  
  p <- rasterVis:::levelplot(rsin, margin=F, par.settings = this_theme, colorkey=leg,
                             at = brks, maxpixels=ncell(rsin)) + 
    layer(sp.lines(grat,lwd=0.5,lty=2,col="grey 50")) +
    layer(sp.polygons(wrld_simpl,lwd=0.8,col="black"))
  return(p)
}

#figure details
grat <- gridlines(wrld_simpl, easts=seq(-180,180,by=20), norths=seq(-90,90,by=20))

#loop through crops
cross_2_all <- list(earliest=c(),mean=c(),latest=c())
for (i in 1:nrow(thresh_val)) {
  #i <- 2
  crop_name <- paste(thresh_val$crops[i])
  cat("\n...processing crop=",crop_name,"\n")
  
  #folder of dfil_dir per crop
  dfil_crop <- paste(dfil_dir,"/",gsub("\\.tif","",crop_name),sep="")
  
  if (exists("cross_stk")) rm(list=c("cross_stk","dc_out_stk"))
  cross_all <- list(cross1=c(),cross2=c())
  for (gcm in gcm_list[-grep("eco_ensemble",gcm_list)]) {
    #gcm <- gcm_list[1]
    
    #load processed output
    load(file=paste(dfil_crop,"/crossinverse_",rcp,"_",gcm,".RData",sep=""))
    
    #put into raster stack
    cross_all$cross2 <- c(cross_all$cross2, cross_stk)
    
    #remove any previous objects and load data for this GCM
    rm(list=c("cross_stk","dc_out_stk"))
  }
  
  cross_all$cross2 <- stack(cross_all$cross2)
  
  #put together the three rasters i need for each
  load(file=paste(dfil_crop,"/crossinverse_",rcp,"_eco_ensemble.RData",sep=""))
  
  calcmean <- function(x) {
    if (length(which(is.na(x))) >= round(length(x)/2)) {
      y <- NA
    } else if (length(which(x == 2090)) >= round(length(x)/2)) {
      y <- 2095
    } else if (length(which(x == 2015)) >= round(length(x)/2)) {
      y <- 2014
    } else if (length(which(x < 0)) >= round(length(x)/2)) {
      y <- NA
    } else {
      x <- x[which(x > 2015 & x < 2090)]; y <- mean(x, na.rm=T)
    }
    return(y)
  }
  
  calcmin <- function(x) {
    if (length(which(is.na(x))) >= round(length(x)/2)) {
      y <- NA
    } else if (length(which(x == 2090)) >= round(length(x)/2)) {
      y <- 2095
    } else if (length(which(x == 2015)) >= round(length(x)/2)) {
      y <- 2014
    } else if (length(which(x < 0)) >= round(length(x)/2)) {
      y <- NA
    } else {
      x <- x[which(x > 2015 & x < 2090)]; y <- min(x, na.rm=T)
    }
    return(y)
  }
  
  calcmax <- function(x) {
    if (length(which(is.na(x))) >= round(length(x)/2)) {
      y <- NA
    } else if (length(which(x >= 2089)) >= round(length(x)/2)) {
      y <- 2095
    } else if (length(which(x == 2015)) >= round(length(x)/2)) {
      y <- 2014
    } else if (length(which(x < 0)) >= round(length(x)/2)) {
      y <- NA
    } else {
      x <- x[which(x > 2015 & x < 2090)]; y <- max(x, na.rm=T)
    }
    return(y)
  }
  
  ctime <- 2
  crosstime <- c(calc(cross_all[[paste("cross",ctime,sep="")]], fun=calcmin),
                 calc(cross_all[[paste("cross",ctime,sep="")]], fun=calcmean),
                 calc(cross_all[[paste("cross",ctime,sep="")]], fun=calcmax))
  crosstime <- stack(crosstime); names(crosstime) <- c("Earliest","Mean","Latest")
  #crosstime[which(crosstime[] < 0)] <- NA
  #crosstime[which(crosstime[] > 2089)] <- 2095
  #crosstime[which(crosstime[] == 2015)] <- 2014
  
  #plot figure
  #tplot <- rs_levplot2(crosstime,zn=NA,zx=NA,nb=NA,brks=c(seq(2010,2090,by=5),2095),scale="RdYlGn",col_i=NA,col_f=NA,ncol=9,rev=T,
  #                     leg=list(at=c(seq(2010,2090,by=5),2095),labels=c("Now",paste(seq(2015,2090,by=5)),"No Gain")))
  #pdf(paste(fig_dir,"/crossing_time_",ctime,"_",gsub("\\.tif","",crop_name),"_",rcp,".pdf",sep=""), height=6,width=12,pointsize=16)
  #print(tplot)
  #dev.off()
  #setwd(fig_dir)
  #system(paste("convert -verbose -density 300 crossing_time_",ctime,"_",gsub("\\.tif","",crop_name),"_",rcp,".pdf -quality 100 -sharpen 0x1.0 -alpha off crossing_time_",ctime,"_",gsub("\\.tif","",crop_name),"_",rcp,".png",sep=""))
  #setwd("~")
  
  #append into multi-crop list
  cross_2_all$earliest <- c(cross_2_all$earliest, crosstime[["Earliest"]])
  cross_2_all$mean <- c(cross_2_all$mean, crosstime[["Mean"]])
  cross_2_all$latest <- c(cross_2_all$latest, crosstime[["Latest"]])
}

### potential suitability gains phase
#plot earliest for all crops
plot_rs <- stack(cross_2_all$earliest)
names(plot_rs) <- c("Banana","Cassava","Bean","F millet","Groundnut","Maize","P millet","Sorghum","Yam")
tplot <- rs_levplot2(plot_rs,zn=NA,zx=NA,nb=NA,brks=c(seq(2010,2090,by=5),2095),scale="RdYlGn",col_i=NA,col_f=NA,ncol=9,rev=T,
                     leg=list(at=c(seq(2010,2090,by=5),2095),labels=c("Now",paste(seq(2015,2090,by=5)),"No Gain")))
pdf(paste(fig_dir,"/crossinverse_time_2_all-crops_earliest_",rcp,".pdf",sep=""), height=8,width=8,pointsize=16)
print(tplot)
dev.off()
setwd(fig_dir)
system(paste("convert -verbose -density 300 crossinverse_time_2_all-crops_earliest_",rcp,".pdf -quality 100 -sharpen 0x1.0 -alpha off crossinverse_time_2_all-crops_earliest_",rcp,".png",sep=""))
setwd("~")

#plot mean for all crops
plot_rs <- stack(cross_2_all$mean)
names(plot_rs) <- c("Banana","Cassava","Bean","F millet","Groundnut","Maize","P millet","Sorghum","Yam")
tplot <- rs_levplot2(plot_rs,zn=NA,zx=NA,nb=NA,brks=c(seq(2010,2090,by=5),2095),scale="RdYlGn",col_i=NA,col_f=NA,ncol=9,rev=T,
                     leg=list(at=c(seq(2010,2090,by=5),2095),labels=c("Now",paste(seq(2015,2090,by=5)),"No Gain")))
pdf(paste(fig_dir,"/crossinverse_time_2_all-crops_mean_",rcp,".pdf",sep=""), height=8,width=8,pointsize=16)
print(tplot)
dev.off()
setwd(fig_dir)
system(paste("convert -verbose -density 300 crossinverse_time_2_all-crops_mean_",rcp,".pdf -quality 100 -sharpen 0x1.0 -alpha off crossinverse_time_2_all-crops_mean_",rcp,".png",sep=""))
setwd("~")

#plot latest for all crops
plot_rs <- stack(cross_2_all$latest)
names(plot_rs) <- c("Banana","Cassava","Bean","F millet","Groundnut","Maize","P millet","Sorghum","Yam")
tplot <- rs_levplot2(plot_rs,zn=NA,zx=NA,nb=NA,brks=c(seq(2010,2090,by=5),2095),scale="RdYlGn",col_i=NA,col_f=NA,ncol=9,rev=T,
                     leg=list(at=c(seq(2010,2090,by=5),2095),labels=c("Now",paste(seq(2015,2090,by=5)),"No Gain")))
pdf(paste(fig_dir,"/crossinverse_time_2_all-crops_latest_",rcp,".pdf",sep=""), height=8,width=8,pointsize=16)
print(tplot)
dev.off()
setwd(fig_dir)
system(paste("convert -verbose -density 300 crossinverse_time_2_all-crops_latest_",rcp,".pdf -quality 100 -sharpen 0x1.0 -alpha off crossinverse_time_2_all-crops_latest_",rcp,".png",sep=""))
setwd("~")


