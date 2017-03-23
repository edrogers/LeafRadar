#!/bin/bash

baseDir="${HOME}/LeafRadar"
imagesDir="${baseDir}/Graphics"
weatherDir="${imagesDir}/Weather"
fontFileRegular="${imagesDir}/JosefinSans-Regular.ttf"
fontFileBold="${imagesDir}/JosefinSans-Bold.ttf"
blankBoxFile="${imagesDir}/emptybox.png"
outputTempFile="${imagesDir}/box_temp.png"

success=0
attempts=0
while [ $success -eq 0 -a $attempts -lt 1000 ];
do
    curl -s https://query.yahooapis.com/v1/public/yql -d q="select * from weather.forecast where woeid=2443945" -d format=xml > ${baseDir}/weather.xml_NEW
    size=$(du ${baseDir}/weather.xml_NEW | grep -o '^[0-9]\+');
    if [ $size -ge 6 ];
    then
	success=1
	mv ${baseDir}/weather.xml_NEW ${baseDir}/weather.xml
    else
	sleep 60
	let attempts+=1
    fi
done

function getConditionCode {
    # Today is 0, tomorrow is 1, etc.
    day=$1
    let nrCode=$day+2 # Bug fix: off-by-one error for "code" value due to it showing up in yweather:condition block
    echo $(grep "yweather:forecast" ${baseDir}/weather.xml | grep -o "code=\"[^\"]*\"" | grep -o "\"[^\"]*\"" | grep -o "[^\"]*" | awk "NR==${nrCode}")
}
function getConditionLow {
    # Today is 0, tomorrow is 1, etc.
    day=$1
    let nrCode=$day+1
    echo $(grep "yweather:forecast" ${baseDir}/weather.xml | grep -o "low=\"[^\"]*\"" | grep -o "\"[^\"]*\"" | grep -o "[^\"]*" | awk "NR==${nrCode}")
}
function getConditionHigh {
    # Today is 0, tomorrow is 1, etc.
    day=$1
    let nrCode=$day+1
    echo $(grep "yweather:forecast" ${baseDir}/weather.xml | grep -o "high=\"[^\"]*\"" | grep -o "\"[^\"]*\"" | grep -o "[^\"]*" | awk "NR==${nrCode}")
}
function getConditionDay {
    # Today is 0, tomorrow is 1, etc.
    day=$1
    let nrCode=$day+1
    echo $(grep "yweather:forecast" ${baseDir}/weather.xml | grep -o "day=\"[^\"]*\"" | grep -o "\"[^\"]*\"" | grep -o "[^\"]*" | awk "NR==${nrCode}")
}

function convertCodeToPicturePrefix {
    code=$1
    if [ $code -eq 19 -o \
	 $code -eq 20 -o \
	 $code -eq 21 -o \
	 $code -eq 22 -o \
	 $code -eq 26 ]; then
	echo "cloudy"
    elif [ $code -eq 25 -o \
	   $code -eq 28 -o \
	   $code -eq 30 -o \
	   $code -eq 44 ]; then
	echo "partlycloudy"
    elif [ $code -eq 40 ]; then
	echo "partlyrainy"
    elif [ $code -eq 13 -o \
	   $code -eq 14 -o \
	   $code -eq 42 ]; then
	echo "partlysnowy"
    elif [ $code -eq 9 -o \
	   $code -eq 11 -o \
	   $code -eq 12 ]; then
	echo "rainy"
    elif [ $code -eq 16 -o \
	   $code -eq 41 -o \
	   $code -eq 43 -o \
	   $code -eq 46 ]; then
	echo "snowy"
    elif [ $code -eq 32 -o \
	   $code -eq 34 -o \
	   $code -eq 36 ]; then
	echo "sun"
    elif [ $code -eq 3 -o \
	   $code -eq 4 -o \
	   $code -eq 37 -o \
	   $code -eq 38 -o \
	   $code -eq 39 -o \
	   $code -eq 45 -o \
	   $code -eq 47 ]; then
	echo "thunderstorm"
    elif [ $code -eq 1 -o \
	   $code -eq 2 -o \
	   $code -eq 15 -o \
	   $code -eq 23 -o \
	   $code -eq 24 ]; then
	echo "windy"
    elif [ $code -eq 5 -o \
	   $code -eq 6 -o \
	   $code -eq 7 -o \
	   $code -eq 8 -o \
	   $code -eq 10 -o \
	   $code -eq 17 -o \
	   $code -eq 18 -o \
	   $code -eq 35 ]; then 
	echo "wintrymix"
    else
	echo "unknown"
    fi
}	

day0day=$(getConditionDay 0)
day0low=$(getConditionLow 0)
day0high=$(getConditionHigh 0)
day0condition=$(getConditionCode 0)
day1day=$(getConditionDay 1)
day1low=$(getConditionLow 1)
day1high=$(getConditionHigh 1)
day1condition=$(getConditionCode 1)
day2day=$(getConditionDay 2)
day2low=$(getConditionLow 2)
day2high=$(getConditionHigh 2)
day2condition=$(getConditionCode 2)
day3day=$(getConditionDay 3)
day3low=$(getConditionLow 3)
day3high=$(getConditionHigh 3)
day3condition=$(getConditionCode 3)
day0image=$(convertCodeToPicturePrefix ${day0condition})
day1image=$(convertCodeToPicturePrefix ${day1condition})
day2image=$(convertCodeToPicturePrefix ${day2condition})
day3image=$(convertCodeToPicturePrefix ${day3condition})
day0image="'"${weatherDir}"/"${day0image}"_large.png'"
day1image="'"${weatherDir}"/"${day1image}"_small.png'"
day2image="'"${weatherDir}"/"${day2image}"_small.png'"
day3image="'"${weatherDir}"/"${day3image}"_small.png'"
day0low="'Lo: "${day0low}"°'"
day0high="'Hi: "${day0high}"°'"
day1temp="'"${day1high}"°/"${day1low}"°'"
day2temp="'"${day2high}"°/"${day2low}"°'"
day3temp="'"${day3high}"°/"${day3low}"°'"
day1day="'"${day1day}"'"
day2day="'"${day2day}"'"
day3day="'"${day3day}"'"

convert -pointsize 36 -fill black -font ${fontFileBold}    -gravity center -draw "text       -90,-120 'Today'" \
        -pointsize 36 -fill black -font ${fontFileRegular} -gravity center -draw "text        -90,-75 ${day0high}" \
        -pointsize 36 -fill black -font ${fontFileRegular} -gravity center -draw "text        -90,-35 ${day0low}" \
                                                           -gravity center -draw "image over   75,-80 0,0 ${day0image}" \
                                                           -gravity center -draw "image over -115, 70 0,0 ${day1image}" \
        -pointsize 24 -fill black -font ${fontFileBold}    -gravity center -draw "text       -115,130 ${day1day}" \
        -pointsize 24 -fill black -font ${fontFileRegular} -gravity center -draw "text       -115,160 ${day1temp}" \
                                                           -gravity center -draw "image over    0, 70 0,0 ${day2image}" \
        -pointsize 24 -fill black -font ${fontFileBold}    -gravity center -draw "text          0,130 ${day2day}" \
        -pointsize 24 -fill black -font ${fontFileRegular} -gravity center -draw "text          0,160 ${day2temp}" \
                                                           -gravity center -draw "image over  115, 70 0,0 ${day3image}" \
        -pointsize 24 -fill black -font ${fontFileBold}    -gravity center -draw "text        115,130 ${day3day}" \
        -pointsize 24 -fill black -font ${fontFileRegular} -gravity center -draw "text        115,160 ${day3temp}" \
    ${blankBoxFile} ${outputTempFile};

exit 0
