#!/usr/bin/env bash

# if [[ ! $(ls ${WORK_DIR} | grep adm) ]]; then
if [[ ! -d ${WORK_DIR}/adm ]]; then

    wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} \
        ftp://${FTP_SERVER}/adm-release-${1:-latest}.zip
    unzip -q ${WORK_DIR}/adm-release-${1:-latest}.zip -d ${WORK_DIR} >/dev/null 2>&1
    rm ${WORK_DIR}/adm-release-${1:-latest}.zip
    cp -r /opt/touchon/files/. ${WORK_DIR}/adm/
    chown -R www-data:www-data ${WORK_DIR}/adm
    find ${WORK_DIR}/adm -type f -exec chmod 644 {} \+
    find ${WORK_DIR}/adm -type d -exec chmod 755 {} \+
    chmod -R ug+rwx ${WORK_DIR}/adm/storage ${WORK_DIR}/adm/bootstrap/cache
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} << EOF
DROP DATABASE IF EXISTS $MYSQL_DATABASE;
CREATE DATABASE $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL ON $MYSQL_DATABASE.* to '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF
    php ${WORK_DIR}/adm/artisan config:clear
    composer -d ${WORK_DIR}/adm dump-autoload

    if [[ ${1:-latest} == "latest" ]]; then
        php ${WORK_DIR}/adm/artisan migrate --seed --force
        mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} << EOF
INSERT INTO smarthome.users (id, login, password, remember_token, created_at, updated_at, type) 
VALUES (NULL, '${ADM_SUPERADMIN_USER}', '${ADM_SUPERADMIN_PASSWORD}', NULL, NOW(), NOW(), 'superadmin');
EOF
    fi

    # sed -i 's,APP_TIMEZONE=.*,APP_TIMEZONE='"${timeZone:-Europe/Moscow}"',g' ${WORK_DIR}/adm/.env
    php ${WORK_DIR}/adm/artisan key:generate --force
    # php ${WORK_DIR}/adm/artisan config:clear

    [[ -L ${WORK_DIR}/adm/storage/app/scripts ]] || ln -s ${WORK_DIR}/server/userscripts ${WORK_DIR}/adm/storage/app/scripts

else

    echo "ADM already installed"

fi
