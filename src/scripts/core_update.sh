#!/usr/bin/env bash

if [[ -d ${WORK_DIR}/server ]]; then

    php ${WORK_DIR}/server/server.php stop -g

    mv ${WORK_DIR}/server ${WORK_DIR}/server.bak

    wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} \
        ftp://${FTP_SERVER}/core-release-${1:-latest}.zip
    unzip -q ${WORK_DIR}/core-release-${1:-latest}.zip -d ${WORK_DIR} >/dev/null 2>&1
    rm ${WORK_DIR}/core-release-${1:-latest}.zip

    sed -i "s/\$host =.*/\$host = getenv(\'MYSQL_HOST\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbname =.*/\$dbname = getenv(\'MYSQL_DATABASE\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbuser =.*/\$dbuser = getenv(\'MYSQL_USER\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbpass =.*/\$dbpass = getenv(\'MYSQL_PASSWORD\');/g" ${WORK_DIR}/server/include.php
    sed -i 's/php -f thread.php/cd \".ROOT_DIR.\" \&\& php -f thread.php/' ${WORK_DIR}/server/classes/SendSocket.php

    composer -n -d ${WORK_DIR}/server clearcache
    composer -n -d ${WORK_DIR}/server require workerman/workerman
    composer -n -d ${WORK_DIR}/server require aldas/modbus-tcp-client
    composer -n -d ${WORK_DIR}/server require davidpersson/beanstalk

    php ${WORK_DIR}/server/server.php start -d ${SERVER_OPTIONS}
    # supervisorctl start socketserver

    if [[ -f ${WORK_DIR}/server/readme.md ]]; then
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/readme.md)
    else
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/README.MD)
    fi
    echo "[OK] Core ver.$coreCurrentVersion installed"

    # rm -rf ${WORK_DIR}/server.bak
    
else
    echo "Core is not installed"
fi