#!/usr/bin/env bash

printenv > /etc/environment

# supervisorctl start mysql

# until [ -S "/run/mysqld/mysqld.sock" ]
# do
#     sleep 1
# done

# source ./mysql_setup.sh

# mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql

# if [ -d /var/lib/mysql/$MYSQL_DATABASE ] ; then 
#     if [[ $(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SHOW TABLES LIKE 'settings'" $MYSQL_DATABASE) ]]; then
#         if [[ $(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SELECT EXISTS (SELECT 1 FROM settings)" $MYSQL_DATABASE) ]]; then
#             timeZone=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SELECT value FROM $MYSQL_DATABASE.settings WHERE name='time_zone';")
#         fi
#     fi
# fi

# ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && echo Europe/Moscow > /etc/timezone

# mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql -sse "SET GLOBAL time_zone = 'Europe/Moscow';"

# phpVersion=$(php -v | head -n 1 | awk '/PHP/ {print $2}' | cut -d. -f1,2)
# sed -i 's,.*date.timezone =.*,date.timezone = 'Europe/Moscow',g' /etc/php/${phpVersion}/fpm/php.ini
# sed -i 's,.*date.timezone =.*,date.timezone = 'Europe/Moscow',g' /etc/php/${phpVersion}/cli/php.ini
# sed -i 's,;clear_env = no,clear_env = no,g' /etc/php/${phpVersion}/fpm/pool.d/www.conf
# sed -i 's,user =.*,user = root,' /etc/php/${phpVersion}/fpm/pool.d/www.conf
# sed -i 's,group =.*,group = root,' /etc/php/${phpVersion}/fpm/pool.d/www.conf

# [[ -L /usr/sbin/php-fpm ]] || ln -s /usr/sbin/php-fpm${phpVersion} /usr/sbin/php-fpm
# supervisorctl restart php-fpm
# [[ -L /run/php/php-fpm.sock ]] || ln -s /run/php/php${phpVersion}-fpm.sock /run/php/php-fpm.sock

# if [ ! -z "$(ls -A /etc/nginx/sites-enabled)" ]; then
#    rm /etc/nginx/sites-enabled/*
# fi

# envsubst "\$WORK_DIR" < ${WORK_DIR}/.temp/nginx.conf.template > /etc/nginx/conf.d/touchon.conf
# supervisorctl restart nginx

# sed -i \
#     -e 's,api:.*,api: yes,g' \
#     -e 's,apiAddress:.*,apiAddress: :9997,g' \
#     -e 's,rtmp:.*,rtmp: no,g' \
#     -e 's,rtsp:.*,rtsp: no,g' \
#     -e 's,webrtc:.*,webrtc: no,g' \
#     -e 's,srt:.*,srt: no,g' \
#     -e 's,hlsVariant:.*,hlsVariant: fmp4,g' \
#     -e 's,hlsAlwaysRemux:.*,hlsAlwaysRemux: true,g' \
#     -e 's,rtspTransport:.*,rtspTransport: tcp,g' \
#     /opt/mediamtx/mediamtx.yml

# supervisorctl restart mediamtx

# if [[ -f ${WORK_DIR}/server/server.php ]]; then
#     cd ${WORK_DIR}/server && php server.php start ${SERVER_OPTIONS:-} & >> /dev/null 2>&1
# fi

# crontab -r
# crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php cron.php 1'; } | crontab -
# crontab -l | { cat; echo '*/5 * * * * cd ${WORK_DIR}/server && php cron.php 5'; } | crontab -
# crontab -l | { cat; echo '*/10 * * * * cd ${WORK_DIR}/server && php cron.php 10'; } | crontab -
# crontab -l | { cat; echo '*/15 * * * * cd ${WORK_DIR}/server && php cron.php 15'; } | crontab -
# crontab -l | { cat; echo '*/30 * * * * cd ${WORK_DIR}/server && php cron.php 30'; } | crontab -
# crontab -l | { cat; echo '*/60 * * * * cd ${WORK_DIR}/server && php cron.php 60'; } | crontab -
# crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php main.php'; } | crontab -
# crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php watchdog.php'; } | crontab -
# crontab -l | { cat; echo '@reboot cd ${WORK_DIR}/server && php watchdog.php'; } | crontab -
# crontab -l | { cat; echo '00 01 * * * cd ${WORK_DIR}/scripts && ./backup.sh'; } | crontab -
# crontab -l | { cat; echo '* * * * * cd ${WORK_DIR}/adm && php artisan schedule:run >> /dev/null 2>&1'; } | crontab -

source ./adm_installation.sh develop
source ./core_installation.sh develop

# mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} << EOF
# DELETE FROM smarthome.modbus_slavers_types WHERE type NOT IN ('wb-led','ecodim-dali-gw2');
# EOF