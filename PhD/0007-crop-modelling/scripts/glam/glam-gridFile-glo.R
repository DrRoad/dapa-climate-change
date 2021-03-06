#Julian Ramirez-Villegas
#UoL / CCAFS / CIAT
#May 2012

#get a given domain (from the cells-process.csv), and make a *grid.txt file
#for reference. This file will not be used by GLAM, but it will be needed if you want
#to map the results

#load packages
library(raster)

#load functions
src.dir <- "D:/_tools/dapa-climate-change/trunk/PhD/0007-crop-modelling/scripts"
#src.dir <- "~/PhD-work/_tools/dapa-climate-change/trunk/PhD/0007-crop-modelling/scripts"
source(paste(src.dir,"/glam/glam-runfiles-functions.R",sep=""))
source(paste(src.dir,"/glam/glam-soil-functions.R",sep=""))
source(paste(src.dir,"/glam/glam-make_wth.R",sep=""))
source(paste(src.dir,"/signals/climateSignals-functions.R",sep=""))

#cmDir <- "F:/PhD-work/crop-modelling"
cmDir <- "W:/eejarv/PhD-work/crop-modelling"
#cmDir <- "/nfs/a17/eejarv/PhD-work/crop-modelling"
bDir <- paste(cmDir,"/GLAM",sep="")
cropName <- "gnut"
cropDir <- paste(bDir,"/model-runs/",toupper(cropName),sep="")

#these are the cells that have both yield and rainfall data, and that can be selected
selection <- "v5"
cells <- read.csv(paste(cropDir,"/inputs/calib-cells-selection-",selection,".csv",sep=""))

#get longitude and latitude (row and column)
rs <- raster(paste(bDir,"/climate-signals-yield/",toupper(cropName),"/0_base_grids/igp_dummy.tif",sep=""))
cells$COL <- colFromX(rs,cells$X)
cells$ROW <- rowFromY(rs,cells$Y)

#output folders
dataDir <- paste(cropDir,"/inputs",sep="")
if (!file.exists(dataDir)) {dir.create(dataDir)}
gridDir <- paste(dataDir,"/grid",sep="")
if (!file.exists(gridDir)) {dir.create(gridDir)}
ascDir <- paste(dataDir,"/ascii",sep="")
if (!file.exists(ascDir)) {dir.create(ascDir)}
gsoilDir <- paste(ascDir,"/soil",sep="")
if (!file.exists(gsoilDir)) {dir.create(gsoilDir)}
gsowDir <- paste(ascDir,"/sow",sep="")
if (!file.exists(gsowDir)) {dir.create(gsowDir)}
yieldDir <- paste(ascDir,"/obs",sep="")
if (!file.exists(yieldDir)) {dir.create(yieldDir)}
wthDir <- paste(ascDir,"/wth",sep="")
if (!file.exists(wthDir)) {dir.create(wthDir)}
ygpDir <- paste(ascDir,"/ygp",sep="")
if (!file.exists(ygpDir)) {dir.create(ygpDir)}

######################################################
#write the file
ofil <- paste(gridDir,"/IITMgrid.txt",sep="")
if (!file.exists(ofil)) {
  ofil <- write_gridFile(x=cells,outfile=ofil,fields=list(CELL="CELL",X="X",Y="Y",COL="COL",ROW="ROW"))
}


######################################################
############ SELECTED ZONE AND GRIDCELLS #############
######################################################
#z <- 1
version <- "e"
for (z in 1:5) {
  cell <- cells$CELL[which(cells$ZONE == z & cells$ISSEL_F == 1)]
  ######################################################
  ######################################################
  
  
  #here do some analysis of yield gap
  #zrs <- raster(paste(cDir,"/gnut-zones/zones_lr.asc",sep=""))
  #windows()
  #plot(zrs,col=rev(terrain.colors(5)))
  #points(cells$X[which(cells$ISSEL_F == 1)],cells$Y[which(cells$ISSEL_F == 1)],pch=20,cex=0.75)
  #points(ocells$X[which(ocells$ISSEL == 1)],ocells$Y[which(ocells$ISSEL == 1)],pch=20,cex=0.75)
  #points(out_cells$X[which(out_cells$CELL == 636)],out_cells$Y[which(out_cells$CELL == 636)],pch="+",cex=0.75)
  #plot(wrld_simpl,add=T)
  
  ##calculate yield gap create yield gap parameter file
  z_cells <- cells[cells$CELL %in% cell,]
  
  #failed testing with precalculated spatially constant YGP
  # ym <- mean(z_cells$YIELD_MN)
  # yn <- min(z_cells$YIELD_MN)
  # yx <- max(z_cells$YIELD_MN)
  # 
  # if (nrow(z_cells) > 1) {
  #   cal_ygp <- 1-(yx-ym)/(yx-yn)
  # } else {
  #   cal_ygp <- 1
  # }
  # cells$YGP <- round(cal_ygp,2)
  
  ygpFile <- paste(ygpDir,"/ygp_calz",z,version,".txt",sep="")
  if (!file.exists(ygpFile)) {
    ygpFile <- write_ygp(x=cells,outfile=ygpFile,cell=cell,fields=list(CELL="CELL",X="X",Y="Y",YGP="YGP"))
  }
  
  
  #cat(cal_ygp,"\n")
  
  #barplot(z_cells$YIELD_MN,names.arg=z_cells$CELL)
  #abline(h=ym,col="red")
  
  
  ######################################################
  #soil types file
  #make a soil type file where the soil code is actually each gridcell
  #and then a soils grid file for any selected gridcell
  #these soil data have been derived from the HARMOIZED SOIL DATABASE of FAO
  #see the script gridSoilData.R for details on how the data was obtained
  soilDir <- paste(bDir,"/soil-data/HWSD",sep="")
  solData <- read.csv(paste(soilDir,"/cellValues.csv",sep=""))
  
  #load mask to correct cell numbers
  msk_sol <- raster(paste(soilDir,"/msk",sep=""))
  msk_sol[which(!is.na(msk_sol[]))] <- which(!is.na(msk_sol[]))
  allCells <- msk_sol[which(!is.na(msk_sol[]))]
  
  xys <- as.data.frame(xyFromCell(msk_sol,allCells))
  xys$CELLS_SOL <- allCells
  
  ncFile <- paste(cmDir,"/climate-data/IND-TropMet_day/0_input_data/india_data.nc",sep="")
  ydDir <- paste(cmDir,"/GLAM/climate-signals-yield/GNUT/raster/gridded",sep="")
  
  metFile <- raster(ncFile,band=0)
  yldFile <- raster(paste(ydDir,"/raw/raw-66.asc",sep=""))
  msk <- maskCreate(metFile,yldFile)
  
  xys$CELL <- cellFromXY(msk,cbind(x=xys$x,y=xys$y))
  solData$CELLS_SOL <- solData$CELL; solData$CELL <- NULL
  solData <- merge(solData,xys,by="CELLS_SOL",all=T)
  
  oSolFile <- paste(gsoilDir,"/soiltypes_calz",z,version,".txt",sep="")
  if (!file.exists(oSolFile)) {
    selSolData <- solData[which(solData$CELL %in% cell),]
    oSolFile <- write_soil_types(x=selSolData,outfile=oSolFile,fields=list(CELL="CELL",SAND="SAND",CLAY="CLAY",AREA_FRAC="AREA_FRAC"))
  }
  
  #now need to create the soil codes file
  oSoilGrid <- paste(gsoilDir,"/soilcodes_calz",z,version,".txt",sep="")
  if (!file.exists(oSoilGrid)) {
    oSoilGrid <- write_soilcodes(x=cells,outfile=oSoilGrid,cell=c(cell),fields=list(CELL="CELL",COL="COL",ROW="ROW"))
  }
  
  
  ######################################################
  # planting dates file (rainfed)
  # get the planting date from Sacks et al. (2010)
  sow_rs <- raster(paste(bDir,"/climate-signals-yield/",toupper(cropName),"/calendar/",tolower(cropName),"/plant_start_lr.tif",sep=""))
  cells$SOW_DATE <- extract(sow_rs,cbind(X=cells$X,Y=cells$Y))
  
  osowFile <- paste(gsowDir,"/sowing_calz",z,version,"_start.txt",sep="")
  if (!file.exists(osowFile)) {
    osowFile <- write_sowdates(x=cells,outfile=osowFile,cell=c(cell),fields=list(CELL="CELL",COL="COL",ROW="ROW",SOW_DATE="SOW_DATE"))
  }
  
  
  ######################################################
  # yield file
  method <- "lin"
  
  yields <- stack(paste(bDir,"/climate-signals-yield/",toupper(cropName),"/raster/gridded/",tolower(method),"/",tolower(method),"-",66:94,".asc",sep=""))
  yFile <- paste(yieldDir,"/yield_calz",z,version,"_",method,".txt",sep="")
  if (!file.exists(yFile)) {
    yFile <- write_yield(x=cells,outfile=yFile,yld_stk=yields,yri=66,yrf=94,cell=cell,fields=list(CELL="CELL",X="X",Y="Y"))
  }
  
  
  
  ######################################################
  #write weather (irr and rainfed)
  wthDataDir <- paste(cmDir,"/climate-data/gridcell-data/IND",sep="") #folder with gridded data
  owthDir <- make_wth(x=cells,cell,wthDir=paste(wthDir,"/rfd_calz",z,version,sep=""),wthDataDir,
                      fields=list(CELL="CELL",X="X",Y="Y",SOW_DATE="SOW_DATE"))
  
  
  #Study on groundnuts says that irrigated gnuts in Gujarat are sown between Jan-Feb and harvested
  #between April and May: sown in day 32 [zone 2]
  #in Uttar Pradesh it is 15th November (day 320) [zone 1]
  #in Andhra Pradesh it is 15th November (day 320) [zone 5]
  #in Karnataka and Tamil Nadu it is 15th January (day 15) [zone 5]
  #in Orissa it is 15h November (day 320) [zone 4]
  #in Madhya Pradesh it is 15th November (day 320) [zone 3]
  
  #This info was condensed into a raster file, which has the planting information per
  #Indian groundnut growing zone (that was done manually). Loading it...
  
  rabi_sow <- raster(paste(cropDir,"/",tolower(cropName),"-zones/plant_rabi.asc",sep=""))
  
  icells <- cells; icells$SOW_DATE <- extract(rabi_sow,cbind(x=icells$X,y=icells$Y))
  owthDir <- make_wth(x=icells,cell,wthDir=paste(wthDir,"/irr_calz",z,version,sep=""),wthDataDir,
                      fields=list(CELL="CELL",X="X",Y="Y",SOW_DATE="SOW_DATE"))
  
  
  ######################################################
  #write planting dates once weather figured out (irrigated)
  #bear in mind this is a modified weather
  icells <- cells; icells$SOW_DATE <- extract(rabi_sow,cbind(x=icells$X,y=icells$Y))
  icells$SOW_DATE2 <- icells$SOW_DATE+120
  icells$SOW_DATE[which(icells$SOW_DATE2 > 365)] <- 31
  
  osowFile <- paste(gsowDir,"/sowing_calz",z,version,"_irr.txt",sep="")
  if (!file.exists(osowFile)) {
    osowFile <- write_sowdates(x=icells,outfile=osowFile,cell=c(cell),fields=list(CELL="CELL",COL="COL",ROW="ROW",SOW_DATE="SOW_DATE"))
  }

}


