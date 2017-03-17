#!/bin/bash

area=$1
district=$2
bizDayLow=$3
bizDayHigh=$4
mostLikelyDay=$5
mostLikelyMonth=$6
mostLikelyDate=$7

baseDir="${HOME}/LeafRadar"
imagesDir="${baseDir}/Graphics"
fontFileRegular="${imagesDir}/JosefinSans-Regular.ttf"
fontFileBold="${imagesDir}/JosefinSans-Bold.ttf"
blankBoxFile="${imagesDir}/emptybox.png"
outputHistFile="${baseDir}/Area${area}/${district}_box_hist.png"

bizDaysText=""
if [ ${bizDayLow} -le 0 ]
then
    bizDaysText="'< "${bizDayHigh}" business days'"
else
    bizDaysText="'"${bizDayLow}"-"${bizDayHigh}" business days'";
fi

mostLikelyDayText="'${mostLikelyDay}, ${mostLikelyMonth} ${mostLikelyDate}'";
histBarsImg="'"${baseDir}"/Area${area}/${district}_leaf_hist.png'";

convert -pointsize 42 -fill black -font ${fontFileRegular} -gravity North -draw "text 0,20 'Next Collection:'" \
                                                                          -draw "text 0,70 ${bizDaysText}" \
        -pointsize 24                                      -gravity South -draw "text 0,45 'Most Likely Collection:'" \
                                  -font ${fontFileBold}                   -draw "text 0,15 ${mostLikelyDayText}" \
                                                          -gravity center -draw "image over 0,17 0,0 ${histBarsImg}" \
   ${blankBoxFile} ${outputHistFile};


exit 0
