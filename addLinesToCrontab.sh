#!/bin/bash

env | grep -v '^LS_COLORS=' > /home/${USER}/.bash_profile

sed -i 's|${USER}|'"${USER}"'|g' /home/${USER}/LeafRadar/addLinesToCrontabSudo.sh
sed -i 's|${USER}|'"${USER}"'|g' /home/${USER}/LeafRadar/completeUpdate_Sudo.sh

crontab -l > crontab_user.txt 2> /dev/null

echo "5        6,18 *  4-5 1-5 /home/${USER}/LeafCollection/downloadLeaf.sh                         > /dev/null 2>&1" >> crontab_user.txt
echo "5        6,18 * 8-12 1-5 /home/${USER}/LeafCollection/downloadLeaf.sh                         > /dev/null 2>&1" >> crontab_user.txt
echo "6        6,18 *  4-5 1-5 /home/${USER}/LeafCollection/downloadBrush.sh                        > /dev/null 2>&1" >> crontab_user.txt
echo "6        6,18 * 8-12 1-5 /home/${USER}/LeafCollection/downloadBrush.sh                        > /dev/null 2>&1" >> crontab_user.txt
echo "6        6,18 *    * 1-5 /home/${USER}/Weather/grabWeather.sh                                 > /dev/null 2>&1" >> crontab_user.txt
echo "0           2 *  4-5 1-6 /home/${USER}/LeafRadar/completeUpdate_User.sh                       > /dev/null 2>&1" >> crontab_user.txt
echo "0           2 * 8-12 1-6 /home/${USER}/LeafRadar/completeUpdate_User.sh                       > /dev/null 2>&1" >> crontab_user.txt

crontab -r 2> /dev/null
crontab -i crontab_user.txt

exit 0
