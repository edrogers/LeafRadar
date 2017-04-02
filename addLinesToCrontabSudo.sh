#!/bin/bash

crontab -l > crontab_sudo.txt 2> /dev/null

echo "SHELL=${SHELL}"                                                                                  >> crontab_sudo.txt
echo "PATH=${PATH}"                                                                                    >> crontab_sudo.txt
echo "5 0,4,8,12,16,20 * 3-12 * /home/${USER}/LeafRadar/completeUpdate_Sudo.sh       > /dev/null 2>&1" >> crontab_sudo.txt

crontab -r 2> /dev/null
crontab -i crontab_sudo.txt

exit 0
