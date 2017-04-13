#!/bin/bash

area=$1
district=$2
status=$3
asOfEpoch=$4

baseDir="${HOME}/LeafRadar"
imagesDir="${baseDir}/Graphics"
mapsDir="${baseDir}/Leaf"
areaDir="${baseDir}/Area${area}"
fontFileRegular="${imagesDir}/JosefinSans-Regular.ttf"
fontFileBold="${imagesDir}/JosefinSans-Bold.ttf"
blankBoxFile="${imagesDir}/emptybox.png"
mapLegendFile="'"${imagesDir}"/mapLegend.gif'"
outputHistFile="${areaDir}/${district}_box_maps.png"

mapCropX=200;
mapCropY=200;

areaStrip=$(echo ${area} | bc -l);
districtStrip=$(echo ${district} | bc -l);
areaText="'Area "${areaStrip}"-"${districtStrip}"'"

if [ ".${status}" == ".Done" ]; then
    status="Round Complete"
elif [ ".${status}" == ".Not_Done" ]; then
    status="Season Over"
fi

statusText="'Status: "${status}"'"

asOfDateText=$(TZ='America/Chicago' date -d @${asOfEpoch} +"%A %-m/%-d")
asOfText="'As of "${asOfDateText}"'"

if [ ${asOfEpoch} -lt 1491004800 ];
then
    mapsCoordFile="${baseDir}/madisonStreetsSubdivisions.py"
elif [ ${asOfEpoch} -lt 1491242400 ];
then
    mapsCoordFile="${baseDir}/madisonStreetsSubdivisions_v2.py"
elif [ ${asOfEpoch} -lt 1491602400 ];
then
    mapsCoordFile="${baseDir}/madisonStreetsSubdivisions_v3.py"
elif [ ${asOfEpoch} -lt 1491919200 ];
then
    mapsCoordFile="${baseDir}/madisonStreetsSubdivisions_v4.py"
elif [ ${asOfEpoch} -lt 1492020000 ];
then
    mapsCoordFile="${baseDir}/madisonStreetsSubdivisions_v5.py"
else
    mapsCoordFile="${baseDir}/madisonStreetsSubdivisions_v6.py"
fi
mapsSourceImg="${mapsDir}/${asOfEpoch}-map${areaStrip}.gif"
mapsCropImg="${areaDir}/${district}_crop_maps.png"
mapsCenter=$(grep "^Area${areaStrip}_${districtStrip}=" ${mapsCoordFile} | grep -o "\[[[:digit:]]\{1,\},[[:digit:]]\{1,\}\]");
mapsCenterX=$(echo ${mapsCenter} | grep -o '\[[[:digit:]]\{1,\},' | grep -o '[[:digit:]]\{1,\}');
mapsCenterY=$(echo ${mapsCenter} | grep -o ',[[:digit:]]\{1,\}\]' | grep -o '[[:digit:]]\{1,\}');
mapsSize=$(identify ${mapsSourceImg} | grep -o '[[:digit:]]\{1,\}x[[:digit:]]\{1,\}' | head -1);
mapsSizeX=$(echo ${mapsSize} | grep -o '^[[:digit:]]\{1,\}');
mapsSizeY=$(echo ${mapsSize} | grep -o '[[:digit:]]\{1,\}$');

# Some piece-meal corrections for when the district is right at the edge of the map
if [[ ${areaStrip} -eq 1 ]] && [[ ${districtStrip} -eq 2 ]]; then
    let mapsCenterY+=45
elif [[ ${areaStrip} -eq 1 ]] && [[ ${districtStrip} -eq 3 ]]; then
    let mapsCenterY+=31
elif [[ ${areaStrip} -eq 6 ]] && [[ ${districtStrip} -eq 25 ]]; then
    let mapsCenterY+=32
elif [[ ${areaStrip} -eq 7 ]] && [[ ${districtStrip} -eq 14 ]]; then
    let mapsCenterY+=38
elif [[ ${areaStrip} -eq 7 ]] && [[ ${districtStrip} -eq 15 ]]; then
    let mapsCenterY+=42
elif [[ ${areaStrip} -eq 8 ]] && [[ ${districtStrip} -eq 15 ]]; then
    let mapsCenterX+=55 # Note: this shift is in X
elif [[ ${areaStrip} -eq 10 ]] && [[ ${districtStrip} -eq 15 ]]; then
    let mapsCenterY+=43
fi

mapsMinX=$(echo "${mapsCenterX}-${mapCropX}/2" | bc )
mapsMinY=$(echo "${mapsCenterY}-${mapCropY}/2" | bc )
mapsMaxX=$(echo "${mapsCenterX}+${mapCropX}/2" | bc )
mapsMaxY=$(echo "${mapsCenterY}+${mapCropY}/2" | bc )
if [ ${mapsMinX} -lt 0 ]; then
    let mapsMaxX=${mapsMaxX}-${mapsMinX};
    let mapsMinX=0;
fi
if [ ${mapsMinY} -lt 0 ]; then
    let mapsMaxY=${mapsMaxY}-${mapsMinY};
    let mapsMinY=0;
fi
if [ ${mapsMaxX} -gt ${mapsSizeX} ]; then
    let mapsMinX=${mapsMinX}+${mapsSizeX}-${mapsMaxX};
    let mapsMaxX=${mapsSizeX};
fi
if [ ${mapsMaxY} -gt ${mapsSizeY} ]; then
    let mapsMinY=${mapsMinY}+${mapsSizeY}-${mapsMaxY};
    let mapsMaxY=${mapsSizeY};
fi

convert ${mapsSourceImg} -crop ${mapCropX}x${mapCropY}+${mapsMinX}+${mapsMinY} ${mapsCropImg}
mapsCropImg="'"${mapsCropImg}"'"

# echo "${areaText}"
# echo "${statusText}"
# echo "${asOfText}"
# echo "mapsCenter  == ${mapsCenter}"
# echo "mapsCenterX == ${mapsCenterX}"
# echo "mapsCenterY == ${mapsCenterY}"
# echo "mapsSize    == ${mapsSize}"
# echo "mapsSizeX   == ${mapsSizeX}"
# echo "mapsSizeY   == ${mapsSizeY}"
# echo "mapsMinX    == ${mapsMinX}"
# echo "mapsMinY    == ${mapsMinY}"
# echo "mapsMaxX    == ${mapsMaxX}"
# echo "mapsMaxY    == ${mapsMaxY}"

statusPointSize=42
if [ ".${status}" == ".Round Complete" ];
then
    statusPointSize=36
fi

convert -pointsize 60 -fill black     -font ${fontFileRegular} -gravity North -draw "text 0,30 ${areaText}" \
        -pointsize ${statusPointSize} -font ${fontFileBold}    -gravity South -draw "text 0,55 ${statusText}" \
        -pointsize 36                 -font ${fontFileRegular}                -draw "text 0,18 ${asOfText}" \
                                                          -gravity center -draw "image over 50,-10 0,0 ${mapsCropImg}" \
                                                          -gravity center -draw "image over -115,-10 0,0 ${mapLegendFile}" \
   ${blankBoxFile} ${outputHistFile};


exit 0
