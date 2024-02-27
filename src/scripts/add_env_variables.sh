#!/usr/bin/env bash

# export MYSQL_ROOT_PASSWORD=$(openssl rand -base64 9)
# echo "export MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> ~/.bashrc

export MYSQL_PASSWORD=$(openssl rand -base64 9)
echo "export MYSQL_PASSWORD=$MYSQL_PASSWORD" >> ~/.bashrc

export SERVER_LOCAL_IP=$(ip -4 addr show dev eth0 | grep eth0:1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "export SERVER_LOCAL_IP=$SERVER_LOCAL_IP" >> ~/.bashrc