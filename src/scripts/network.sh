#!/usr/bin/env bash

echo "sudo service networking restart" > ${WORK_DIR}/.hostpipe

for (( i=1; i <= 20; i++ ))
do

    echo "sudo systemctl is-active networking" > ${WORK_DIR}/.hostpipe
    sleep 0.5

    if [[ $(cat ${WORK_DIR}/.dockerpipe) == 'active' ]]; then
        echo > ${WORK_DIR}/.dockerpipe
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