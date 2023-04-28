#!/usr/bin/env bash

if [[ ! -d ${WORK_DIR}/server ]]; then

    if wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} \
        ftp://${FTP_SERVER}/core-release-${1:-latest}.zip; then
        echo "[OK] core-release-${1:-latest}.zip downloaded"
    else
        echo "[ERR] core-release-${1:-latest}.zip download failed"
        exit 1
    fi

    if unzip -q ${WORK_DIR}/core-release-${1:-latest}.zip -d ${WORK_DIR} >/dev/null 2>&1; then
        echo "[OK] core-release-${1:-latest}.zip unziped"
    else
        echo "[ERR] core-release-${1:-latest}.zip unzip failed"
        exit 1
    fi
    
    rm ${WORK_DIR}/core-release-${1:-latest}.zip
    sed -i "s/\$host =.*/\$host = getenv(\'MYSQL_HOST\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbname =.*/\$dbname = getenv(\'MYSQL_DATABASE\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbuser =.*/\$dbuser = getenv(\'MYSQL_USER\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbpass =.*/\$dbpass = getenv(\'MYSQL_PASSWORD\');/g" ${WORK_DIR}/server/include.php
    sed -i \
      's/php -f thread.php/cd \".ROOT_DIR.\" \&\& php -f thread.php/' ${WORK_DIR}/server/classes/SendSocket.php
    chown -R www-data:www-data ${WORK_DIR}/server/userscripts
    chmod -R 770 ${WORK_DIR}/server/userscripts

    if [[ -f ${WORK_DIR}/server/readme.md ]]; then
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/readme.md)
    else
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/README.MD)
    fi

    echo "[OK] Core ver.$coreCurrentVersion installed"

else

    echo "CORE already installed"

fi
