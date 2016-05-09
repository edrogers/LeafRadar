#!/bin/bash
source /home/${USER}/.bash_profile

workingDir="/home/${USER}/LeafRadar"

${workingDir}/downloadLeaf.sh
${workingDir}/downloadBrush.sh
${workingDir}/generateCSV.py
${workingDir}/generateForecast.sh

exit
