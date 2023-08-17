#!/usr/bin/env bash

printenv > /etc/environment

if [[ ! -d ${WORK_DIR}/mysql ]]; then
    mv /var/lib/mysql ${WORK_DIR}/
fi

supervisorctl start mysql
sleep 5
source /opt/touchon/scripts/mysql_setup.sh
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql

timeZone=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -sse "SELECT value FROM $MYSQL_DATABASE.settings WHERE name='time_zone';")
ln -snf /usr/share/zoneinfo/${timeZone:-Europe/Moscow} /etc/localtime && echo ${timeZone:-Europe/Moscow} > /etc/timezone
sed -i 's,.*date.timezone =.*,date.timezone = '"${timeZone:-Europe/Moscow}"',g' /etc/php/7.4/fpm/php.ini
sed -i 's,.*date.timezone =.*,date.timezone = '"${timeZone:-Europe/Moscow}"',g' /etc/php/7.4/cli/php.ini
mysql -u$MYSQL_USER -p$MYSQL_ROOT_PASSWORD mysql -sse "SET GLOBAL time_zone = '$timeZone';"

supervisorctl start php-fpm

envsubst "\$WORK_DIR" < /opt/touchon/configs/nginx.conf.template > /opt/touchon/configs/nginx.conf

supervisorctl start nginx

# source /opt/touchon/scripts/adm_installation.sh
# source /opt/touchon/scripts/core_installation.sh

sed -i 's,APP_TIMEZONE=.*,APP_TIMEZONE='"${timeZone:-Europe/Moscow}"',g' ${WORK_DIR}/adm/.env