#!/usr/bin/env bash

echo "sudo service networking restart" > /opt/touchon/hostpipe
# echo "[NOTICE] Network service restart command executed"

# for (( i=1; i <= 20; i++ ))
# do

#     echo "sudo systemctl is-active networking" > /opt/touchon/hostpipe
#     sleep 0.5

#     if [[ $(cat /opt/touchon/dockerpipe) == 'active' ]]; then
#         echo "[OK] Network service is active"
#         echo > /opt/touchon/dockerpipe
#         break
#     fi

#     if [[ $i == 20 ]]; then
#         echo "[ERROR] Waiting too long"
#     fi

# done

# ip1=$(ip -4 addr show dev eth0 | grep eth0:1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# ip2=$(ip -4 addr show dev eth0 | grep eth0:2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# if [[ $ip1 == $1 ]] && [[ $ip2 == $2 ]]; then
# echo "[OK] New settings applied"
# else
# echo "[ERROR] Something went wrong"
# fi