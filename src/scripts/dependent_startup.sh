#!/usr/bin/env bash

printenv > /etc/environment

# supervisorctl start mysql

until [ -S "/run/mysqld/mysqld.sock" ]
do
    sleep 1
done

source ${WORK_DIR}/scripts/mysql_setup.sh

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql

if [ -d /var/lib/mysql/$MYSQL_DATABASE ] ; then 
    if [[ $(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SHOW TABLES LIKE 'settings'" $MYSQL_DATABASE) ]]; then
        if [[ $(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SELECT EXISTS (SELECT 1 FROM settings)" $MYSQL_DATABASE) ]]; then
            timeZone=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SELECT value FROM $MYSQL_DATABASE.settings WHERE name='time_zone';")
        fi
    fi
fi

ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && echo Europe/Moscow > /etc/timezone

# TIMEZONE_CHECK=$(printf 'SELECT EXISTS (SELECT * FROM mysql.time_zone_name WHERE NAME LIKE "%s")' "${timeZone:-Europe/Moscow}")
# if [[ ! $(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "$TIMEZONE_CHECK") ]]; then
#     mysql_tzinfo_to_sql /usr/share/zoneinfo/${timeZone:-Europe/Moscow} ${timeZone:-Europe/Moscow} | mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql
# fi

mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql -sse "SET GLOBAL time_zone = 'Europe/Moscow';"

phpVersion=$(php -v | head -n 1 | awk '/PHP/ {print $2}' | cut -d. -f1,2)
sed -i 's,.*date.timezone =.*,date.timezone = 'Europe/Moscow',g' /etc/php/${phpVersion}/fpm/php.ini
sed -i 's,.*date.timezone =.*,date.timezone = 'Europe/Moscow',g' /etc/php/${phpVersion}/cli/php.ini
sed -i 's,;clear_env = no,clear_env = no,g' /etc/php/${phpVersion}/fpm/pool.d/www.conf
sed -i 's,user =.*,user = root,' /etc/php/${phpVersion}/fpm/pool.d/www.conf
sed -i 's,group =.*,group = root,' /etc/php/${phpVersion}/fpm/pool.d/www.conf

[[ -L /usr/sbin/php-fpm ]] || ln -s /usr/sbin/php-fpm${phpVersion} /usr/sbin/php-fpm
supervisorctl restart php-fpm
[[ -L /run/php/php-fpm.sock ]] || ln -s /run/php/php${phpVersion}-fpm.sock /run/php/php-fpm.sock

if [ ! -z "$(ls -A /etc/nginx/sites-enabled)" ]; then
   rm /etc/nginx/sites-enabled/*
fi

envsubst "\$WORK_DIR" < ${WORK_DIR}/configs/nginx.conf.template > /etc/nginx/conf.d/touchon.conf
supervisorctl restart nginx

# if [[ ! -f ${WORK_DIR}/adm/.env ]]; then
#     sed -i 's,APP_TIMEZONE=.*,APP_TIMEZONE='"${timeZone:-Europe/Moscow}"',g' ${WORK_DIR}/adm/.env
# fi

# chmod +x ${WORK_DIR}/scripts/* && chmod +x ${WORK_DIR}/scripts/rs_control/rs_control
# [[ -L /usr/bin/rs_control ]] || ln -s ${WORK_DIR}/scripts/rs_control/rs_control /usr/bin/rs_control

sed -i \
    -e 's,api:.*,api: yes,g' \
    -e 's,apiAddress:.*,apiAddress: :9997,g' \
    -e 's,rtmp:.*,rtmp: no,g' \
    -e 's,rtsp:.*,rtsp: no,g' \
    -e 's,webrtc:.*,webrtc: no,g' \
    -e 's,srt:.*,srt: no,g' \
    -e 's,hlsVariant:.*,hlsVariant: fmp4,g' \
    -e 's,hlsAlwaysRemux:.*,hlsAlwaysRemux: true,g' \
    -e 's,rtspTransport:.*,rtspTransport: tcp,g' \
    /opt/mediamtx/mediamtx.yml

supervisorctl restart mediamtx

# php ${WORK_DIR}/adm/artisan config:clear

# if [[ -f ${WORK_DIR}/server/server.php ]]; then
#     cd ${WORK_DIR}/server && php server.php start ${SERVER_OPTIONS:-} & >> /dev/null 2>&1
# fi

# cd ${WORK_DIR}/server/scripts && php modbusctl.php start

crontab -r
crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php cron.php 1'; } | crontab -
crontab -l | { cat; echo '*/5 * * * * cd ${WORK_DIR}/server && php cron.php 5'; } | crontab -
crontab -l | { cat; echo '*/10 * * * * cd ${WORK_DIR}/server && php cron.php 10'; } | crontab -
crontab -l | { cat; echo '*/15 * * * * cd ${WORK_DIR}/server && php cron.php 15'; } | crontab -
crontab -l | { cat; echo '*/30 * * * * cd ${WORK_DIR}/server && php cron.php 30'; } | crontab -
crontab -l | { cat; echo '*/60 * * * * cd ${WORK_DIR}/server && php cron.php 60'; } | crontab -
crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php main.php'; } | crontab -
crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php watchdog.php'; } | crontab -
crontab -l | { cat; echo '00 01 * * * cd ${WORK_DIR}/scripts && ./backup.sh'; } | crontab -
crontab -l | { cat; echo '* * * * * cd ${WORK_DIR}/adm && php artisan schedule:run >> /dev/null 2>&1'; } | crontab -

source ${WORK_DIR}/scripts/adm_installation.sh 1.16
source ${WORK_DIR}/scripts/core_installation.sh 1.13

mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} << EOF
INSERT INTO smarthome.modbus_buses (device, type, baudrate, length, parity, stopbits) 
VALUES ('/dev/ttyUSB0', 'rtu', 9600, 8, 'none', 1);
INSERT INTO smarthome.modbus_buses (device, type, baudrate, length, parity, stopbits) 
VALUES ('/dev/ttyUSB1', 'rtu', 9600, 8, 'none', 1);
EOF

mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} << EOF
DELETE FROM smarthome.modbus_slavers_types WHERE type NOT IN ('wb-led','ecodim-dali-gw2');
EOF

cat << EOT >> ${WORK_DIR}/configs/supervisord.conf
[program:modbus1]
command = php modbus_queue.php 1 -DFOREGROUND
directory = %(ENV_WORK_DIR)s/server/scripts
autostart = true
autorestart = unexpected
exitcodes = 6
stderr_logfile = %(ENV_WORK_DIR)s/logs/modbus1.err.log
stdout_logfile = %(ENV_WORK_DIR)s/logs/modbus1.out.log

[program:modbus2]
command = php modbus_queue.php 2 -DFOREGROUND
directory = %(ENV_WORK_DIR)s/server/scripts
autostart = true
autorestart = unexpected
exitcodes = 6
stderr_logfile = %(ENV_WORK_DIR)s/logs/modbus2.err.log
stdout_logfile = %(ENV_WORK_DIR)s/logs/modbus2.out.log

[program:modbus1_polling]
command = php modbus_polling_loop.php 1 -DFOREGROUND
directory = %(ENV_WORK_DIR)s/server/scripts
autostart = true
autorestart = unexpected
exitcodes = 6
stderr_logfile = %(ENV_WORK_DIR)s/logs/modbus1_polling.err.log
stdout_logfile = %(ENV_WORK_DIR)s/logs/modbus1_polling.out.log

[program:modbus2_polling]
command = php modbus_polling_loop.php 2 -DFOREGROUND
directory = %(ENV_WORK_DIR)s/server/scripts
autostart = true
autorestart = unexpected
exitcodes = 6
stderr_logfile = %(ENV_WORK_DIR)s/logs/modbus2_polling.err.log
stdout_logfile = %(ENV_WORK_DIR)s/logs/modbus2_polling.out.log
EOT

rm -rf ${WORK_DIR}/scripts/rs_control
rm -f ${WORK_DIR}/scripts/adm_*
rm -f ${WORK_DIR}/scripts/core_*
rm -f ${WORK_DIR}/scripts/touchon/src/scripts/dependent_startup.sh
rm -f ${WORK_DIR}/configs/nginx.conf.template