#!/usr/bin/env bash

cat << EOF > ${WORK_DIR}/hostpipe
echo $1 > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1 $1/" /etc/hosts
EOF
