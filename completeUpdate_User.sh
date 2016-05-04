#!/bin/bash

workingDir="/home/ed/Documents/LeafRadar"

${workingDir}/downloadLeaf.sh
${workingDir}/downloadBrush.sh
${workingDir}/generateCSV.py
${workingDir}/generateForecast.sh

exit
