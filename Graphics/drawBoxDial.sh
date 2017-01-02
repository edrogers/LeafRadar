#!/bin/bash

area=$1
district=$2
statusMon=$3
statusTue=$4
statusWed=$5
statusThu=$6
statusFri=$7

baseDir="${HOME}/LeafRadar"
imagesDir="${baseDir}/Graphics"
dialPiecesDir="${imagesDir}/Dial"
areaDir="${baseDir}/Area${area}"
fontFileRegular="${imagesDir}/JosefinSans-Regular.ttf"
fontFileBold="${imagesDir}/JosefinSans-Bold.ttf"
blankBoxFile="${imagesDir}/shadowbox.png"
mapLegendFile="'"${imagesDir}"/mapLegend.gif'"
outputHistFile="${areaDir}/${district}_box_dial.png"

let area=$(echo ${area} | sed -e 's|^0||')

fontMon=${fontFileRegular}
fontTue=${fontFileRegular}
fontWed=${fontFileRegular}
fontThu=${fontFileRegular}
fontFri=${fontFileRegular}
colorMon="grey"
colorTue="grey"
colorWed="grey"
colorThu="grey"
colorFri="grey"

statusMonFile="'"${dialPiecesDir}"/mon-"${statusMon}
statusTueFile="'"${dialPiecesDir}"/tue-"${statusTue}
statusWedFile="'"${dialPiecesDir}"/wed-"${statusWed}
statusThuFile="'"${dialPiecesDir}"/thu-"${statusThu}
statusFriFile="'"${dialPiecesDir}"/fri-"${statusFri}

legendCurrentFile="'"${dialPiecesDir}"/box-current.png'"
legendNextFile="'"${dialPiecesDir}"/box-next.png'"
legendDoneFile="'"${dialPiecesDir}"/box-done.png'"
legendNotDoneFile="'"${dialPiecesDir}"/box-notdone.png'"

let sideOfTown=${area}%2;
if [ $sideOfTown -eq 0 ]; then
    sideOfTown="West"
else
    sideOfTown="East"
fi

status="Unknown";
if [ $area -gt 8 ]; then
    dayOfWeek="Friday"
    statusFriFile=${statusFriFile}"-selected";
    fontFri=${fontFileBold};
    colorFri="black";
    if [ ".${statusFri}" == ".current" ]; then
	status="Current";
    elif [ ".${statusFri}" == ".next" ]; then
	status="Next";
    elif [ ".${statusFri}" == ".done" ]; then
	status="Done";
    elif [ ".${statusFri}" == ".notdone" ]; then
	status="Not Done";
    fi
elif [ $area -gt 6 ]; then
    dayOfWeek="Thursday"
    statusThuFile=${statusThuFile}"-selected";
    fontThu=${fontFileBold};
    colorThu="black";
    if [ ".${statusThu}" == ".current" ]; then
	status="Current";
    elif [ ".${statusThu}" == ".next" ]; then
	status="Next";
    elif [ ".${statusThu}" == ".done" ]; then
	status="Done";
    elif [ ".${statusThu}" == ".notdone" ]; then
	status="Not Done";
    fi
elif [ $area -gt 4 ]; then
    dayOfWeek="Wednesday"
    statusWedFile=${statusWedFile}"-selected";
    fontWed=${fontFileBold};
    colorWed="black";
    if [ ".${statusWed}" == ".current" ]; then
	status="Current";
    elif [ ".${statusWed}" == ".next" ]; then
	status="Next";
    elif [ ".${statusWed}" == ".done" ]; then
	status="Done";
    elif [ ".${statusWed}" == ".notdone" ]; then
	status="Not Done";
    fi
elif [ $area -gt 2 ]; then
    dayOfWeek="Tuesday"
    statusTueFile=${statusTueFile}"-selected";
    fontTue=${fontFileBold};
    colorTue="black";
    if [ ".${statusTue}" == ".current" ]; then
	status="Current";
    elif [ ".${statusTue}" == ".next" ]; then
	status="Next";
    elif [ ".${statusTue}" == ".done" ]; then
	status="Done";
    elif [ ".${statusTue}" == ".notdone" ]; then
	status="Not Done";
    fi
else
    dayOfWeek="Monday"
    statusMonFile=${statusMonFile}"-selected";
    fontMon=${fontFileBold};
    colorMon="black";
    if [ ".${statusMon}" == ".current" ]; then
	status="Current";
    elif [ ".${statusMon}" == ".next" ]; then
	status="Next";
    elif [ ".${statusMon}" == ".done" ]; then
	status="Done";
    elif [ ".${statusMon}" == ".notdone" ]; then
	status="Not Done";
    fi
fi

statusMonFile=${statusMonFile}".png'";
statusTueFile=${statusTueFile}".png'";
statusWedFile=${statusWedFile}".png'";
statusThuFile=${statusThuFile}".png'";
statusFriFile=${statusFriFile}".png'";

# mapCropX=200;
# mapCropY=200;

# areaStrip=$(echo ${area} | bc -l);
# districtStrip=$(echo ${district} | bc -l);
# areaText="'Area "${areaStrip}"-"${districtStrip}"'"

# if [ ".${status}" == ".Recently_Done" ]; then
#     status="Done"
# fi
# statusText="'Status: "${status}"'"

# asOfDateText=$(date -d @${asOfEpoch} +"%A %-m/%-d")
# asOfText="'As of "${asOfDateText}"'"

# mapsCoordFile="${baseDir}/madisonStreetsSubdivisions.py"
# mapsSourceImg="${mapsDir}/${asOfEpoch}-map${areaStrip}.gif"
# mapsCropImg="${areaDir}/${district}_crop_maps.png"
# mapsCenter=$(grep "^Area${areaStrip}_${districtStrip}=" ${mapsCoordFile} | grep -o "\[[[:digit:]]\{1,\},[[:digit:]]\{1,\}\]");
# mapsCenterX=$(echo ${mapsCenter} | grep -o '\[[[:digit:]]\{1,\},' | grep -o '[[:digit:]]\{1,\}');
# mapsCenterY=$(echo ${mapsCenter} | grep -o ',[[:digit:]]\{1,\}\]' | grep -o '[[:digit:]]\{1,\}');
# mapsSize=$(identify ${mapsSourceImg} | grep -o '[[:digit:]]\{1,\}x[[:digit:]]\{1,\}' | head -1);
# mapsSizeX=$(echo ${mapsSize} | grep -o '^[[:digit:]]\{1,\}');
# mapsSizeY=$(echo ${mapsSize} | grep -o '[[:digit:]]\{1,\}$');

# mapsMinX=$(echo "${mapsCenterX}-${mapCropX}/2" | bc )
# mapsMinY=$(echo "${mapsCenterY}-${mapCropY}/2" | bc )
# mapsMaxX=$(echo "${mapsCenterX}+${mapCropX}/2" | bc )
# mapsMaxY=$(echo "${mapsCenterY}+${mapCropY}/2" | bc )
# if [ ${mapsMinX} -lt 0 ]; then
#     let mapsMaxX=${mapsMaxX}-${mapsMinX};
#     let mapsMinX=0;
# fi
# if [ ${mapsMinY} -lt 0 ]; then
#     let mapsMaxY=${mapsMaxY}-${mapsMinY};
#     let mapsMinY=0;
# fi
# if [ ${mapsMaxX} -gt ${mapsSizeX} ]; then
#     let mapsMinX=${mapsMinX}+${mapsSizeX}-${mapsMaxX};
#     let mapsMaxX=${mapsSizeX};
# fi
# if [ ${mapsMaxY} -gt ${mapsSizeY} ]; then
#     let mapsMinY=${mapsMinY}+${mapsSizeY}-${mapsMaxY};
#     let mapsMaxY=${mapsSizeY};
# fi

# convert ${mapsSourceImg} -crop ${mapCropX}x${mapCropY}+${mapsMinX}+${mapsMinY} ${mapsCropImg}
# mapsCropImg="'"${mapsCropImg}"'"

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

# convert -pointsize 60 -fill black -font ${fontFileRegular} -gravity North -draw "text 0,30 ${areaText}" \
#         -pointsize 42             -font ${fontFileBold}    -gravity South -draw "text 0,55 ${statusText}" \
#         -pointsize 36             -font ${fontFileRegular}                -draw "text 0,18 ${asOfText}" \
#                                                           -gravity center -draw "image over 50,-10 0,0 ${mapsCropImg}" \
#                                                           -gravity center -draw "image over -115,-10 0,0 ${mapLegendFile}" \
#    ${blankBoxFile} ${outputHistFile};

HeaderText1="'${sideOfTown} Side, ${dayOfWeek} Collection'"
HeaderText2="'Status: ${status}'"

convert -gravity center -draw "image over 0,20 0,0 ${statusMonFile}" \
        -gravity center -draw "image over 0,20 0,0 ${statusTueFile}" \
        -gravity center -draw "image over 0,20 0,0 ${statusWedFile}" \
        -gravity center -draw "image over 0,20 0,0 ${statusThuFile}" \
        -gravity center -draw "image over 0,20 0,0 ${statusFriFile}" \
        -gravity center -pointsize 18 -fill ${colorMon} -font ${fontMon} -draw "text  29, -20 'Mon'" \
        -gravity center -pointsize 18 -fill ${colorTue} -font ${fontTue} -draw "text  48,  35 'Tue'" \
        -gravity center -pointsize 18 -fill ${colorWed} -font ${fontWed} -draw "text   0,  70 'Wed'" \
        -gravity center -pointsize 18 -fill ${colorThu} -font ${fontThu} -draw "text -48,  35 'Thu'" \
        -gravity center -pointsize 18 -fill ${colorFri} -font ${fontFri} -draw "text -29, -20 'Fri'" \
        -gravity north  -pointsize 24 -fill black       -font ${fontFileRegular} -draw "text 0, 24 ${HeaderText1}" \
        -gravity north  -pointsize 30 -fill black       -font ${fontFileBold}    -draw "text 0, 60 ${HeaderText2}" \
        -gravity south  -draw "image over -100,50 0,0 ${legendCurrentFile}" \
        -gravity south  -draw "image over -100,20 0,0 ${legendNextFile}" \
        -gravity south  -draw "image over  20,50 0,0  ${legendDoneFile}" \
        -gravity south  -draw "image over  20,20 0,0  ${legendNotDoneFile}" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text -50,48 'Current'" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text -59,18 'Next'" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text 65,48 'Done'" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text 82,18 'Not Done'" \
   ${blankBoxFile} ${outputHistFile};


exit 0
