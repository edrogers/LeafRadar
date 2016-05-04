#!/bin/bash

crontab -l > crontab_sudo.txt 2> /dev/null

echo "0  3 * 4-12 1-6 /home/ed/Documents/LeafRadar/completeUpdate_Sudo.sh                 > /dev/null 2>&1" >> crontab_sudo.txt

crontab -r 2> /dev/null
crontab -i crontab_sudo.txt

exit 0