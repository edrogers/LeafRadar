#!/bin/bash
workingDir="/home/${USER}/LeafRadar"

${workingDir}/moveForecastToWeb.sh
cp -p ${workingDir}/Graphics/box_temp.png /var/www/html/
exit
