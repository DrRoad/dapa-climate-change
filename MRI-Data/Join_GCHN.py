# --------------------------------------------------------------------
# Description : Join Extracted Shps with GCHN data stations by months
# Author : Carlos Navarro
#---------------------------------------------------------------------

import arcgisscripting, os, sys
gp = arcgisscripting.create(9.3)

if len(sys.argv) < 5:
	os.system('cls')
	print "\n Too few args"
	print "   - ie: python Join_GCHN.py E:\MRI_Analysis\Joined\tmax_monthly_latin 1979 2003 E:\MRI_Analysis\GHCN_Tables\tmax"
	sys.exit(1)

dirbase = sys.argv[1]
inityear = int(sys.argv[2])
finalyear = int(sys.argv[3])
dirghcn = sys.argv[4]

os.system('cls')

gp.workspace = dirbase 

print "~~~~~~~~~~~~~~~~~~~~"
print "     JOIN FIELDS    "
print "~~~~~~~~~~~~~~~~~~~~"

for year in range(inityear, finalyear + 1, 1):
    InData = "tmax_" + str(year) + "01.shp"
    InFeature = dirghcn + "\\" + str(year) + ".dbf"    
    print "---> Joining tmax_" + str(year)
    gp.joinfield (InData, "STATION_ID", InFeature, "STATION_ID", "JAN; FEB; MAR; APR; MAY; JUN; JUL; AUG; SEP; OCT; NOV; DEC")
    print InFeature + " Joined!"

print "Done!!"
