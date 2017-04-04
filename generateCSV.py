#!/usr/bin/python

from PIL import Image
import os
import re
import math
import madisonStreetsSubdivisions
import madisonStreetsSubdivisions_v2
import madisonStreetsSubdivisions_v3

dirName=os.path.dirname(os.path.realpath(__file__))
dataSourceDir="{}/Leaf".format(dirName)
dataSourceDirContents=os.listdir(dataSourceDir)
csvOutputFilename="{}/mapStatuses.csv".format(dirName)
with open(csvOutputFilename,'w') as csvOutputFile :
    csvOutputFile.write("Time Stamp,District,Area,Status\n")
timeStampRegEx=re.compile("\d{10,}")
districtRegEx=re.compile("map\d+.pdf$")
digitsRegEx=re.compile("\d+")
#Open the data directory and convert all PDFs to GIFs for each area
mapPDFs=[]
#First, open the data dir and append all (correctly named) files to
# a list of files to search through.
for filename in dataSourceDirContents:
    if districtRegEx.search(filename) != None:
        if timeStampRegEx.match(filename) != None:
            mapPDFs.append(filename)
mapPDFs.sort()
for mapPDF in mapPDFs :
    timeStamp=timeStampRegEx.match(mapPDF).group()
    if int(timeStamp) < 1491004800:
        AllDistricts      = madisonStreetsSubdivisions.AllDistricts
        AllDistrictsNames = madisonStreetsSubdivisions.AllDistrictsNames
        NotDoneStatuses   = madisonStreetsSubdivisions.NotDoneStatuses
        DoneStatuses      = madisonStreetsSubdivisions.DoneStatuses
        CurrentStatuses   = madisonStreetsSubdivisions.CurrentStatuses
        NextStatuses      = madisonStreetsSubdivisions.NextStatuses
    elif int(timeStamp) < 1491242400:
        AllDistricts      = madisonStreetsSubdivisions_v2.AllDistricts
        AllDistrictsNames = madisonStreetsSubdivisions_v2.AllDistrictsNames
        NotDoneStatuses   = madisonStreetsSubdivisions_v2.NotDoneStatuses
        DoneStatuses      = madisonStreetsSubdivisions_v2.DoneStatuses
        CurrentStatuses   = madisonStreetsSubdivisions_v2.CurrentStatuses
        NextStatuses      = madisonStreetsSubdivisions_v2.NextStatuses
    else:
        AllDistricts      = madisonStreetsSubdivisions_v3.AllDistricts
        AllDistrictsNames = madisonStreetsSubdivisions_v3.AllDistrictsNames
        NotDoneStatuses   = madisonStreetsSubdivisions_v3.NotDoneStatuses
        DoneStatuses      = madisonStreetsSubdivisions_v3.DoneStatuses
        CurrentStatuses   = madisonStreetsSubdivisions_v3.CurrentStatuses
        NextStatuses      = madisonStreetsSubdivisions_v3.NextStatuses


    districtNum=int(digitsRegEx.search(districtRegEx.search(mapPDF).group()).group())-1
    mapGIF=mapPDF.replace(".pdf",".gif")
    fname="{}/{}".format(dataSourceDir,mapGIF)
    if (not os.path.isfile(fname)):
        os.system("convert {}/{} {}/{}".format(dataSourceDir,mapPDF,
                                               dataSourceDir,mapGIF))
    #convert GIF to RGB
    mapIMG=Image.open("{}/{}".format(dataSourceDir,mapGIF))
    mapRGB=mapIMG.convert('RGB')

    #Check legend for pixel definitions for each of the four status
    Status = ["Not Done","Done","Current","Next"]

    nd_color   = mapRGB.getpixel((NotDoneStatuses[districtNum][0],NotDoneStatuses[districtNum][1]))
    dn_color   = mapRGB.getpixel((DoneStatuses[districtNum][0],DoneStatuses[districtNum][1]))
    cr_color   = mapRGB.getpixel((CurrentStatuses[districtNum][0],CurrentStatuses[districtNum][1]))
    nx_color   = mapRGB.getpixel((NextStatuses[districtNum][0],NextStatuses[districtNum][1]))

    #Now check the pixel color for each area in the district
    areasInDistrict=AllDistricts[districtNum]
    for i, area in enumerate(areasInDistrict) :
        areaName=AllDistrictsNames[districtNum][i]
        areaColor=mapRGB.getpixel((area[0],area[1]))
        #Find the district status color with the smallest RMS distance
        # to this areaColor in RGB space
        ndDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(nd_color,areaColor)])
        dnDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(dn_color,areaColor)])
        crDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(cr_color,areaColor)])
        nxDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(nx_color,areaColor)])
        distList = [ndDist, dnDist, crDist, nxDist]
        areaStatus = Status[distList.index(min(distList))]
        with open(csvOutputFilename,'a') as csvOutputFile :
            csvOutputFile.write("{},{},{},{}\n".format(timeStamp,districtNum,areaName,areaStatus))

quit()
