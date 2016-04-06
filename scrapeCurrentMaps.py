#!/usr/bin/python

import requests
import os
from time import sleep,time
from datetime import datetime, date
from madisonStreetsSubdivisions import AllDistricts,AllDistrictsNames,NotDoneStatuses,DoneStatuses,CurrentStatuses,NextStatuses
from PIL import Image
import math
import errno

dirName=os.path.dirname(os.path.realpath(__file__))

logfilename="{}/errorlog.txt".format(dirName)
urlBase="http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_"
outputCSVname="{}/currentStatus.csv".format(dirName)
timeStamp=int(time())

#Remove the old status file
staleFilesToRemove=[outputCSVname]
for i in range(10) :
    staleFilesToRemove.append("map{}.pdf".format(i))
    staleFilesToRemove.append("map{}.gif".format(i))

for staleFile in staleFilesToRemove :
    try:
        os.remove(staleFile)
    except OSError as e:
        if e.errno != errno.ENOENT: # errno.ENOENT = no such file or directory
            logfile = open(logfilename,'a')
            className = "ERROR:"
            logfile.write("{} {dt:%c}; {}: {}\n".format(className,type(e),e,dt=datetime.now()))
            logfile.close()
            raise
        else :
            pass

#Start a new status file
with open(outputCSVname,'a') as outputCSV :
    outputCSV.write("Time Stamp,District,Area,Status\n")
    
for i in range(10) :
    districtNum=i
    
    #Download a map
    httpRequestURL="{}{}.pdf".format(urlBase,i+1)
    r=requests.get(httpRequestURL)
    mapFileName="{}/map{}.pdf".format(dirName,i)
    mapFile = open(mapFileName,'wb')
    mapFile.write(r.content)
    mapFile.close()

    #Convert the map content
    mapFileGIFName="{}/map{}.gif".format(dirName,i)
    print "convert {} {}".format(mapFileName,
                                mapFileGIFName)

    os.system("convert {} {}".format(mapFileName,
                                    mapFileGIFName))
    #Convert GIF to RGB
    mapIMG=Image.open("{}".format(mapFileGIFName))
    mapRGB=mapIMG.convert('RGB')

    #Check legend for pixel definitions for each of the four status
    Status = ["Not Done","Done","Current","Next"]

    nd_color   = mapRGB.getpixel((NotDoneStatuses[districtNum][0],NotDoneStatuses[districtNum][1]))
    dn_color   = mapRGB.getpixel((DoneStatuses[districtNum][0],DoneStatuses[districtNum][1]))
    cr_color   = mapRGB.getpixel((CurrentStatuses[districtNum][0],CurrentStatuses[districtNum][1]))
    nx_color   = mapRGB.getpixel((NextStatuses[districtNum][0],NextStatuses[districtNum][1]))

    #Now check the pixel color for each area in the district
    areasInDistrict=AllDistricts[districtNum]
    for iArea, area in enumerate(areasInDistrict) :
        areaName=AllDistrictsNames[districtNum][iArea]
        areaColor=mapRGB.getpixel((area[0],area[1]))
        #Find the district status color with the smallest RMS distance
        # to this areaColor in RGB space
        ndDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(nd_color,areaColor)])
        dnDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(dn_color,areaColor)])
        crDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(cr_color,areaColor)])
        nxDist = sum([math.sqrt((x-y)*(x-y)) for x,y in zip(nx_color,areaColor)])
        distList = [ndDist, dnDist, crDist, nxDist]
        areaStatus = Status[distList.index(min(distList))]
        with open(outputCSVname,'a') as outputCSV :
            outputCSV.write("{},{},{},{}\n".format(timeStamp,districtNum,areaName,areaStatus))

    sleep(5)



