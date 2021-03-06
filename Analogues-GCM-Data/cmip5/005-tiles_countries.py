# ---------------------------------------------------------------------------------
# Author: Carlos Navarro
# Date: 23-7-2012
# Purpose: Create tile from GCM data
# ----------------------------------------------------------------------------------

import arcpy, os, sys, string, glob, grid2asciitiff_tiles
from arcpy import env

#Syntax
if len(sys.argv) < 6:
	os.system('cls')
	print "\n Too few args"
	print "   - ie: python 005-tiles_countries.py U:\portals\ccafs-analogues\grid_files rcp26 U:\portals\ccafs-analogues\TilesByCountry 30s 2020_2049 0 200"
	sys.exit(1)

#Set variables
dirbase = sys.argv[1]
rcp = sys.argv[2]
dirout = sys.argv[3]
resolution = sys.argv[4]
period = sys.argv[5]
start = sys.argv[6]
end = sys.argv[7]

os.system('cls')
# if resolution == "30s":
	# countrytilelist = "cod", "nzl", "ssd", "fji", "jpn", "afg", "ago", "arg", "aus", "bfa", "bgd", "bhs", "blr", "bol", "bra", "bwa", "caf", "can", "chl", "chn", "civ", "cmr", "cog", "col",\
		# "cub", "deu", "dnk", "dza", "ecu", "egy", "eri", "esh", "esp", "fin", "fji", "fra", "gab", "gbr", "gha", "gin", "gnq", "grc", "grl",\
		# "guy", "hrv", "idn", "ind", "irn", "irq", "isl", "ita", "jpn", "kaz", "kgz", "khm", "kir", "kor", "lao", "lby", "mar", "mdg",\
		# "mdv", "mex", "mli", "mlt", "mmr", "mng", "moz", "mrt", "mus", "mwi", "mys", "nam", "ncl", "ner", "nic", "nga", "nor", "npl",  "omn",\
		# "pak", "per", "phl", "png", "pol", "prk", "prt", "pry", "pyf", "rom",  "sau", "sdn", "sen", "sgp", "sjm", "slb", "som", "swe",\
		# "syr", "tca", "tcd", "tha", "tjk", "tkm", "tun", "tur", "ukr", "ury",  "uzb", "ven", "vnm", "vut", "yem", "zaf",\
		# "zmb", "zwe", "nzl", "rus", "usa", "eth", "tza", "ken", "uga"
		

		
# elif resolution == "2_5min":
	# countrytilelist = "arg", "aus", "bra", "can", "chl", "chn", "grl", "idn", "ind", "kaz", "rus", "usa"

l = open(dirbase+"\\"+"listcountries_"+resolution+".list", "r")	
countrytilelist = [i for i in l.readlines()]
				
countryDic = {"ala": "1 1 ","alb": "1 1 ","and": "1 1 ","are": "1 1 ","arm": "1 1 ","atg": "1 1 ","aut": "1 1 ","aze": "1 1 ","cod": "6 6 ", "kna": "1 1 ", "mne": "1 1 ", "nru": "1 1 ", "plw": "1 1 ", "pse": "1 1 ", "srb": "1 1 ", "ssd": "3 3 ", "tls": "1 1 ", "tto": "1 1 ", "tuv": "1 1 ",\
			"btn": "1 1 ","brn": "1 1 ","brb": "1 1 ","bmu": "1 1 ","bih": "1 1 ","blz": "1 1 ","bhi": "1 1 ","bhr": "1 1 ","bhr": "1 1 ","bdi": "1 1 ", "bel": "1 1 ", "ben": "1 1 ", "bfa": "2 2 ", "bgd": "2 2 ", "bhs": "2 2 ", "blr": "2 2 ", "bwa": "2 2 ","bgr": "2 2 ", "civ": "2 2 ", "cmr": "2 2 ", "cog": "2 2 ", "cub": "2 2 ",\
			"che": "1 1 ","deu": "2 2 ", "dnk": "2 2 ", "eri": "2 2 ", "esh": "2 2 ", "gab": "2 2 ", "gha": "2 2 ", "gin": "2 2 ", "gnq": "2 2 ", "grc": "2 2 ", "guy": "2 2 ",\
			"hrv": "2 2 ", "irq": "2 2 ", "isl": "2 2 ", "ken": "2 2 ", "kgz": "2 2 ", "khm": "2 2 ", "kir": "2 2 ", "kor": "2 2 ", "lao": "2 2 ", "mus": "2 2 ",\
			"mwi": "2 2 ", "ncl": "2 2 ", "nic": "2 2 ", "npl": "2 2 ", "omn": "2 2 ", "pol": "2 2 ", "prk": "2 2 ", "pry": "2 2 ", "pyf": "2 2 ", "rom": "2 2 ",\
			"sen": "2 2 ", "sgp": "2 2 ", "slb": "2 2 ", "syr": "2 2 ", "tca": "2 2 ", "tjk": "2 2 ", "tun": "2 2 ", "uga": "2 2 ", "ury": "2 2 ",\
			"vut": "2 2 ", "yem": "2 2 ", "zwe": "2 2 ", "afg": "3 3 ", "ago": "3 3 ", "bol": "3 3 ", "caf": "3 3 ", "ecu": "3 3 ", "egy": "3 3 ",\
			"eth": "3 3 ", "fin": "3 3 ", "fra": "3 3 ", "gbr": "3 3 ", "ita": "3 3 ", "mar": "3 3 ", "mdg": "3 3 ", "mdv": "3 3 ",\
			"mmr": "3 3 ", "moz": "3 3 ", "mrt": "3 3 ", "mys": "3 3 ", "nam": "3 3 ", "ner": "3 3 ", "nga": "3 3 ", "phl": "3 3 ", "png": "3 3 ",\
			"som": "3 3 ", "swe": "3 3 ", "tcd": "3 3 ", "tha": "3 3 ", "tkm": "3 3 ", "tur": "3 3 ", "tza": "3 3 ", "ukr": "3 3 ", "uzb": "3 3 ",\
			"ven": "3 3 ", "vnm": "3 3 ", "zmb": "3 3 ", "col": "4 4 ", "esp": "4 4 ", "irn": "4 4 ", "lby": "4 4 ", "mli": "4 4 ", "mlt": "4 4 ",\
			"mng": "4 4 ", "nor": "4 4 ", "pak": "4 4 ", "per": "4 4 ", "prt": "4 4 ", "sau": "4 4 ", "sdn": "4 4 ", "dza": "5 5 ", "mex": "5 5 ", "sjm": "5 5 ",\
			"zaf": "5 5 ", "arg": "2 2 ", "idn": "2 2 ", "jpn": "1 1 ", "kaz": "2 2 ", "ind": "2 2 ", "bra": "3 3 ", "chl": "3 3 ",\
			"grl": "3 3 ", "aus": "3 3 ", "chn": "3 3 ", "fji": "1 1 ", "can": "4 4 ", "nzl": "5 5 ", "rus": "7 7 ", "usa": "8 8 ",\
"ala": "1 1 ", "alb": "1 1 ", "asm": "1 1 ", "and": "1 1 ", "aia": "1 1 ", "atg": "1 1 ", "arm": "1 1 ", "abw": "1 1 ", "bhs": "1 1 ", "bhr": "1 1 ", "brb": "1 1 ", "bel": "1 1 ", "blz": "1 1 ", "bmu": "1 1 ", "btn": "1 1 ", "bih": "1 1 ", "bvt": "1 1 ", "iot": "1 1 ", "vgb": "1 1 ", "brn": "1 1 ", "bdi": "1 1 ", "cpv": "1 1 ", "cym": "1 1 ", "cxr": "1 1 ", "cck": "1 1 ", "com": "1 1 ", "cok": "1 1 ", "cri": "1 1 ", "cyp": "1 1 ", "dji": "1 1 ", "dma": "1 1 ", "slv": "1 1 ", "imn": "1 1 ", "isr": "1 1 ", "gnq": "1 1 ", "flk": "1 1 ", "fji": "1 1 ", "fro": "1 1 ", "pyf": "1 1 ", "atf": "1 1 ", "gmb": "1 1 ", "gib": "1 1 ", "grd": "1 1 ", "glp": "1 1 ", "gum": "1 1 ", "ggy": "1 1 ", "gnb": "1 1 ", "hti": "1 1 ", "hmd": "1 1 ", "hkg": "1 1 ", "jam": "1 1 ", "jey": "1 1 ", "kir": "1 1 ", "kwt": "1 1 ", "lbn": "1 1 ", "lso": "1 1 ", "lie": "1 1 ", "lux": "1 1 ", "mac": "1 1 ", "mkd": "1 1 ", "mdv": "1 1 ", "mlt": "1 1 ", "mhl": "1 1 ", "mtq": "1 1 ", "mus": "1 1 ", "myt": "1 1 ", "fsm": "1 1 ", "mda": "1 1 ", "mco": "1 1 ", "mne": "1 1 ", "msr": "1 1 ", "ncl": "1 1 ", "niu": "1 1 ", "nfk": "1 1 ", "mnp": "1 1 ", "plw": "1 1 ", "pse": "1 1 ", "pcn": "1 1 ", "pri": "1 1 ", "qat": "1 1 ", "nru": "1 1 ", "nld": "1 1 ", "ant": "1 1 ", "dom": "1 1 ", "reu": "1 1 ", "rwa": "1 1 ", "shn": "1 1 ", "kna": "1 1 ", "spm": "1 1 ", "sgs": "1 1 ", "sp-": "1 1 ", "lka": "1 1 ", "che": "1 1 ", "swz": "1 1 ", "twn": "1 1 ", "tls": "1 1 ", "tgo": "1 1 ", "tkl": "1 1 ", "ton": "1 1 ", "tto": "1 1 ", "tca": "1 1 ", "tuv": "1 1 ", "umi": "1 1 ", "vut": "1 1 ", "vat": "1 1 ", "vir": "1 1 ", "wlf": "1 1 ", "ko-": "1 1 ", "vct": "1 1 ", "wsm": "1 1 ", "smr": "1 1 ", "lca": "1 1 ", "stp": "1 1 ", "syc": "1 1 ", "sle": "1 1 ", "sgp": "1 1 ", "svk": "1 1 ", "svn": "1 1 ", "slb": "1 1 ",\
"cze": "2 2 ","est": "2 2 ","geo": "2 2 ","gtm": "2 2 ","hnd": "2 2 ","guf": "2 2 ","hun": "2 2 ","irl": "2 2 ","jor": "2 2 ","lbr": "2 2 ","ltu": "2 2 ","pan": "1 1 ","sur": "1 1 "
		}

	
for country in countrytilelist[int(start):int(end)]:
# for country in countrytilelist:
	country = country.split("_")[0]
	out = dirout + "\\" + rcp +"\\"+ country + "_" + str(resolution)
	checkFile = out + "_tiles_countries_done.txt"
	if not os.path.exists(checkFile):
		
		input = dirbase + "\\" + rcp +"\\"+ country + "_" + str(resolution)
		modellist = sorted(os.listdir(input))
		
		print "~~~~~~~~~~~~~~~~~~~"
		print "  TILES COUNTRIES  RCP: ",rcp
		print "~~~~~~~~~~~~~~~~~~~"
		
		for model in modellist:
			if model != "current":
				# arcpy.env.workspace = input + "\\" + model
				# diroutGrids = dirout + "\\baseline_new\\" + country + "_" + str(resolution) + "\\" + model + "\\1960_1990"
			# else:
				arcpy.env.workspace = input + "\\" + model + "\\" + str(period)
				diroutGrids = out + "\\" + model + "\\" + str(period)
				
			print "\nProcessing",rcp,country,model,period,"\n"

			rasterList = arcpy.ListRasters("*", "GRID")
			for raster in rasterList:

				if os.path.basename(raster).split("_")[0] == "bio" or os.path.basename(raster).split("_")[0] == "prec" or os.path.basename(raster).split("_")[0] == "tmean" or os.path.basename(raster).split("_")[0] == "dtr":
					
					diroutGridsVar = diroutGrids + "\\" + os.path.basename(raster).split("_")[0]+"_tif"
					if not os.path.exists(diroutGridsVar):
						os.system('mkdir ' + diroutGridsVar)
					if model != "current":
						# tileTif= "baseline_1960_1990_"+model+"_"+raster + "_" + str(int(str(countryDic [country]).split(" ")[0]) * int(str(countryDic [country]).split(" ")[1]) - 1)+".tif"
					# else:
						tileTif= rcp+"_"+period+"_"+model+"_"+raster + "_" + str(int(str(countryDic [country]).split(" ")[0]) * int(str(countryDic [country]).split(" ")[1]) - 1)+".tif"
					
					if not arcpy.Exists(diroutGridsVar + "\\" + rcp+"_"+period+"_"+model+"_"+raster + "_" + str(int(str(countryDic [country]).split(" ")[0]) * int(str(countryDic [country]).split(" ")[1]) - 1)+".tif"):
						
						# trashList = sorted(glob.glob(diroutGridsVar + "\\" + raster + "*.*"))
						# for trashfile in trashList:
							# os.remove(trashfile)
						
						print "\tspliting .. ",raster
						
						# rasterdeleteList = sorted(glob.glob(diroutGridsVar + "\\" + os.path.basename(raster) + "_*"))
						# for rasterdelete in rasterdeleteList:
							# arcpy.Delete_management(rasterdelete)
						if model != "current":
							# arcpy.SplitRaster_management(raster, diroutGridsVar, "baseline_1960_1990_"+model+"_"+raster + "_", "NUMBER_OF_TILES", "TIFF", "#", str(countryDic [country]), "#", "0", "PIXELS", "#", "#")
						# else:
							arcpy.SplitRaster_management(raster, diroutGridsVar, rcp+"_"+period+"_"+model+"_"+raster + "_", "NUMBER_OF_TILES", "TIFF", "#", str(countryDic [country]), "#", "0", "PIXELS", "#", "#")
						# arcpy.SplitRaster_management(raster,diroutGridsVar,raster + "_","NUMBER_OF_TILES","TIFF","NEAREST","4 4","2048 2048","0","PIXELS","#","#")
						# arcpy.SplitRaster_management(raster, diroutGridsVar, raster + "_", "NUMBER_OF_TILES", "GRID", "#", str(countryDic [country]), "#", "0", "PIXELS", "#", "#")
						print "\t" + raster,"tiled"					
						
						# trashList = sorted(glob.glob(diroutGridsVar + "\\" + raster + "*.*"))
						# for trashfile in trashList:
							# os.remove(trashfile)
						
					else:
						print "\t" + raster,"tiled"
				
		#Compressing and delete input files
		# os.system("7za a -mmt8 " + dirbase + "\\SRES_" + sres + "\\downscaled\\" + country + "_" + str(resolution) + ".zip " + dirbase + "\\SRES_" + sres + "\\downscaled\\" + country + "_" + str(resolution))
		# os.system("rmdir /s /q " + dirbase + "\\SRES_" + sres + "\\downscaled\\" + country + "_" + str(resolution))
		
		#Create check file
		checkTXT = open(checkFile, "w")
		checkTXT.close()

	else:
		
		print "\n\t",country," Tiled!"

	# if not os.path.exists(dirout + "\\SRES_" + sres + "\\" + country + "_" + resolution + "_grid2tiff_countries_done.txt"):
		
		##Scenarios
		# grid2asciitiff_tiles.mainfunction(dirout, dirout, country, sres, period, resolution, "YES")
		
		## Compressing country files
		# print " \nCompressing country folder"
		# os.system("7za a -mmt12 " + dirout + "\\SRES_" + sres + "\\" + country + "_" + resolution + ".zip " + dirout + "\\SRES_" + sres + "\\" + country + "_" + resolution)
		# os.system("rmdir /s /q " + dirout + "\\SRES_" + sres + "\\" + country + "_" + resolution)
		# print " \nCompression done!"
		
		# checkTXT = open(dirout + "\\SRES_" + sres + "\\" + country + "_" + resolution + "_grid2tiff_countries_done.txt", "w")
		# checkTXT.close()

		# print "\n",country," Tiles converted!"

	# else:
		# print "\n",country," Tiles converted!"

print "\n Process done!"
