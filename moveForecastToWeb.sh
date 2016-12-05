#!/bin/bash

modelDir="/home/ubuntu/LeafRadar"
webDir="/var/www/html"

cp -p ${modelDir}/todaysForecast.png ${webDir}/
chmod ugo+r ${webDir}/todaysForecast.png

n=1;
while [ $n -le 10 ];
do
   if [ $n -lt 10 ];
   then
      dir=$(echo "Area0${n}");
   else
      dir=$(echo "Area10");
   fi
   rsync -avz ${modelDir}/${dir}/ ${webDir}/${dir}/
   for file in ${webDir}/${dir};
   do
      chmod ugo+r ${file}
   done
   let n+=1;
done

exit 0
