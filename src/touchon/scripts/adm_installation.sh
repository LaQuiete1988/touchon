#!/usr/bin/env bash

if [[ ! -d ${WORK_DIR}/adm ]]; then

    wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} \
        ftp://${FTP_SERVER}/adm-release-${1:-latest}.zip
    unzip -q ${WORK_DIR}/adm-release-${1:-latest}.zip -d ${WORK_DIR} >/dev/null 2>&1
    rm ${WORK_DIR}/adm-release-${1:-latest}.zip

# Очищаем БД
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOF

# Пишем нужные переменные в .env
    cat << EOF > ${WORK_DIR}/adm/.env
APP_NAME="TouchON Admin Panel"
APP_ENV=production
APP_KEY=
APP_DEBUG=true
APP_LOG_LEVEL=debug
APP_URL=http://localhost
APP_TIMEZONE=Europe/Moscow
DEBUGBAR_ENABLED=false
SERVER_FOLDER=${WORK_DIR}/server
IMAGES_BASE_URI=${IMG_MNG_HOST}
DB_CONNECTION=mysql
DB_HOST=${MYSQL_HOST}
DB_PORT=${MYSQL_PORT}
DB_DATABASE=${MYSQL_DATABASE}
DB_USERNAME=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}
BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
QUEUE_DRIVER=sync
EOF

    composer -n -d ${WORK_DIR}/adm install

    php ${WORK_DIR}/adm/artisan config:clear
    php ${WORK_DIR}/adm/artisan key:generate --force
    php ${WORK_DIR}/adm/artisan migrate --seed --force

    mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} << EOF
INSERT INTO smarthome.users (id, login, password, remember_token, created_at, updated_at, type) 
VALUES (NULL, '${ADM_SUPERADMIN_USER}', '${ADM_SUPERADMIN_PASSWORD}', NULL, NOW(), NOW(), 'superadmin');
EOF

# Добавляем симлинк на каталог пользовательских скриптов
    [[ -d ${WORK_DIR}/adm/storage/app/scripts ]] && rm -rf ${WORK_DIR}/adm/storage/app/scripts
    [[ -L ${WORK_DIR}/adm/storage/app/scripts ]] || ln -s ${WORK_DIR}/server/userscripts ${WORK_DIR}/adm/storage/app/scripts

    if [[ -f ${WORK_DIR}/adm/readme.md ]]; then
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/readme.md)
    else
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/README.MD)
    fi
    echo "[OK] Adm ver.$admCurrentVersion has been installed"

else
    echo "Adm is already installed"
fi