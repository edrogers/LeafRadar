#!/bin/bash

crontab -l > crontab_user.txt 2> /dev/null

echo "5        6,18 * 4-12 1-5 /home/${USER}/LeafCollection/downloadLeaf.sh                         > /dev/null 2>&1" >> crontab_user.txt
echo "6        6,18 * 4-10 1-5 /home/${USER}/LeafCollection/downloadBrush.sh                        > /dev/null 2>&1" >> crontab_user.txt
echo "6        6,18 * 4-12 1-5 /home/${USER}/Weather/grabWeather.py                                 > /dev/null 2>&1" >> crontab_user.txt
echo "0           2 * 4-12 1-6 /home/${USER}/LeafRadar/completeUpdate_User.sh                       > /dev/null 2>&1" >> crontab_user.txt

crontab -r 2> /dev/null
crontab -i crontab_user.txt

exit 0
