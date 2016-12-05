#!/bin/bash
workingDir="/home/${USER}/LeafRadar"

${workingDir}/downloadLeaf.sh
${workingDir}/downloadBrush.sh
${workingDir}/generateCSV.py
${workingDir}/generateCSV_Brush.py
${workingDir}/generateForecast.sh

exit
