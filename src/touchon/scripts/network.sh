#!/usr/bin/env bash

echo "sudo service networking restart" > /opt/touchon/hostpipe

for (( i=1; i <= 20; i++ ))
do

    echo "sudo systemctl is-active networking" > /opt/touchon/hostpipe
    sleep 0.5

    if [[ $(cat /opt/touchon/dockerpipe) == 'active' ]]; then
        echo > /opt/touchon/dockerpipe
        break
    fi

    if [[ $i == 20 ]]; then
        exit 62
    fi

done

ip1=$(ip -4 addr show dev eth0 | grep eth0:1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ip2=$(ip -4 addr show dev eth0 | grep eth0:2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [[ $ip1 == $1 ]] && [[ $ip2 == $2 ]]; then
    # echo "[OK] New settings applied"
    exit 0
else
    # echo "[ERROR] Something went wrong"
    exit 255
fi