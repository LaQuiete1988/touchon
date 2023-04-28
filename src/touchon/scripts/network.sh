#!/usr/bin/env bash

cat << EOF > /opt/touchon/hostpipe
cat << AEOF > /etc/network/interfaces.d/netcfg
auto eth0
allow-hotplug eth0
iface eth0 inet static
address 192.168.6.50
netmask 255.255.255.0

auto eth0:1
allow-hotplug eth0:1
iface eth0:1 inet static
address $1
netmask 255.255.255.0
gateway $2

auto eth0:2
allow-hotplug eth0:2
iface eth0:2 inet static
address $3
netmask 255.255.255.0
AEOF
EOF