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
blankBoxFile="${imagesDir}/emptybox.png"
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
	status="Round Complete";
    elif [ ".${statusFri}" == ".notdone" ]; then
	status="Season Over";
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
	status="Round Complete";
    elif [ ".${statusThu}" == ".notdone" ]; then
	status="Season Over";
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
	status="Round Complete";
    elif [ ".${statusWed}" == ".notdone" ]; then
	status="Season Over";
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
	status="Round Complete";
    elif [ ".${statusTue}" == ".notdone" ]; then
	status="Season Over";
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
	status="Round Complete";
    elif [ ".${statusMon}" == ".notdone" ]; then
	status="Season Over";
    fi
fi

statusMonFile=${statusMonFile}".png'";
statusTueFile=${statusTueFile}".png'";
statusWedFile=${statusWedFile}".png'";
statusThuFile=${statusThuFile}".png'";
statusFriFile=${statusFriFile}".png'";

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
        -gravity south  -draw "image over -110,50 0,0 ${legendCurrentFile}" \
        -gravity south  -draw "image over -110,20 0,0 ${legendNextFile}" \
        -gravity south  -draw "image over  10,50  0,0 ${legendDoneFile}" \
        -gravity south  -draw "image over  10,20  0,0 ${legendNotDoneFile}" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text -60,48 'Current'" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text -69,18 'Next'" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text 93,48 'Round Complete'" \
        -gravity south  -pointsize 18 -fill black       -font ${fontFileRegular} -draw "text 80,18 'Season Over'" \
   ${blankBoxFile} ${outputHistFile};


exit 0
