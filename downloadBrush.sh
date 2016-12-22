#!/bin/bash
nowdate=$(date +%s)

dataDir="/home/${USER}/LeafRadar/Brush"

curl http://www.cityofmadison.com/streets/yardWaste/brush/brushWest.cfm -o ${dataDir}/${nowdate}-home.html
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_2.pdf -o ${dataDir}/${nowdate}-map2.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_4.pdf -o ${dataDir}/${nowdate}-map4.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_6.pdf -o ${dataDir}/${nowdate}-map6.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_8.pdf -o ${dataDir}/${nowdate}-map8.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_10.pdf -o ${dataDir}/${nowdate}-map10.pdf

curl http://www.cityofmadison.com/streets/yardWaste/brush/brushEast.cfm -o ${dataDir}/${nowdate}-East-home.html
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_1.pdf -o ${dataDir}/${nowdate}-map1.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_3.pdf -o ${dataDir}/${nowdate}-map3.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_5.pdf -o ${dataDir}/${nowdate}-map5.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_7.pdf -o ${dataDir}/${nowdate}-map7.pdf
curl http://www.cityofmadison.com/streets/documents/brush/BRUSH_COLLECTION_DISTRICT_9.pdf -o ${dataDir}/${nowdate}-map9.pdf

sleep 60

exit
