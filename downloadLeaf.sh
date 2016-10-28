#!/bin/bash
nowdate=$(date +%s)

dataDir="/home/${USER}/LeafRadar/Leaf"

curl http://www.cityofmadison.com/streets/yardWaste/leaf/LeafWest.cfm -o ${dataDir}/${nowdate}-home.html
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_2.pdf -o ${dataDir}/${nowdate}-map2.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_4.pdf -o ${dataDir}/${nowdate}-map4.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_6.pdf -o ${dataDir}/${nowdate}-map6.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_8.pdf -o ${dataDir}/${nowdate}-map8.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_10.pdf -o ${dataDir}/${nowdate}-map10.pdf

curl http://www.cityofmadison.com/streets/yardWaste/leaf/LeafEast.cfm -o ${dataDir}/${nowdate}-East-home.html
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_1.pdf -o ${dataDir}/${nowdate}-map1.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_3.pdf -o ${dataDir}/${nowdate}-map3.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_5.pdf -o ${dataDir}/${nowdate}-map5.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_7.pdf -o ${dataDir}/${nowdate}-map7.pdf
curl http://www.cityofmadison.com/streets/documents/leaf/LEAF_COLLECTION_DISTRICT_9.pdf -o ${dataDir}/${nowdate}-map9.pdf

sleep 60

#Keep only the 10 latest reads
let iTimeStamp=0;
for file in $(ls -1r ${dataDir}/*map10.pdf); do
    let iTimeStamp+=1;
    let timeStamp=$(echo $(basename ${file}) | grep -o '^[[:digit:]]\{1,\}'); 
    if [ ${iTimeStamp} -gt 10 ]; then
	rm ${dataDir}/${timeStamp}-*
    fi
done

exit
