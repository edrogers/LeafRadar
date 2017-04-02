#!/bin/bash

sed -i 's|${USER}|'"${USER}"'|g' /home/${USER}/LeafRadar/addLinesToCrontabSudo.sh
sed -i 's|${USER}|'"${USER}"'|g' /home/${USER}/LeafRadar/completeUpdate_Sudo.sh
sed -i 's|${USER}|'"${USER}"'|g' /home/${USER}/LeafRadar/moveForecastToWeb.sh


crontab -l > crontab_user.txt 2> /dev/null

echo "SHELL=${SHELL}"                                                                                                 >> crontab_user.txt
echo "USER=${USER}"                                                                                                   >> crontab_user.txt
echo "PATH=${PATH}"                                                                                                   >> crontab_user.txt
echo "0    3,7,11,15,19,23 *  3-5 * /home/${USER}/LeafCollection/downloadLeaf.sh                    > /dev/null 2>&1" >> crontab_user.txt
echo "0    3,7,11,15,19,23 * 8-12 * /home/${USER}/LeafCollection/downloadLeaf.sh                    > /dev/null 2>&1" >> crontab_user.txt
echo "1    3,7,11,15,19,23 * 3-10 * /home/${USER}/LeafCollection/downloadBrush.sh                   > /dev/null 2>&1" >> crontab_user.txt
echo "0    3,7,11,15,19,23 *    * * /home/${USER}/Weather/grabWeather.sh                            > /dev/null 2>&1" >> crontab_user.txt
echo "0     0,4,8,12,16,20 * 3-12 * /home/${USER}/LeafRadar/completeUpdate_User.sh                  > /dev/null 2>&1" >> crontab_user.txt

crontab -r 2> /dev/null
crontab -i crontab_user.txt

exit 0
