#!/bin/bash

modelDir="/home/${USER}/LeafRadar"
webDir="/var/www/html"

cp -p ${modelDir}/todaysForecast.png ${webDir}/
chmod ugo+r ${webDir}/todaysForecast.png

exit 0
