#!/usr/bin/env bash

printenv > /etc/environment

if [[ ! -d ${WORK_DIR}/mysql ]]; then
    mv /var/lib/mysql ${WORK_DIR}/
fi

supervisorctl start mysql
sleep 5
source /opt/touchon/scripts/mysql_setup.sh

supervisorctl start php-fpm

envsubst "\$WORK_DIR" < /opt/touchon/configs/nginx.conf.template > /opt/touchon/configs/nginx.conf

supervisorctl start nginx

source /opt/touchon/scripts/core_installation.sh
source /opt/touchon/scripts/adm_installation.sh
