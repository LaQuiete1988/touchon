FROM ubuntu:22.04

ARG WORK_DIR=/opt/touchon
ARG DEBIAN_FRONTEND=noninteractive
ARG FTP_USER
ARG FTP_PASSWORD
ARG FTP_SERVER
ARG ADM_VER
ARG CORE_VER

ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB.UTF-8
ENV LC_ALL=en_GB.UTF-8

WORKDIR ${WORK_DIR}

COPY ./configs ${WORK_DIR}/configs
COPY --chmod=0775 ./scripts ${WORK_DIR}/scripts
COPY ./temp ${WORK_DIR}/.temp

RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests locales locales-all && \
    apt-get install -y --no-install-recommends --no-install-suggests supervisor nginx tzdata \
        iputils-ping cron php8.1-fpm php8.1-bcmath php8.1-mbstring php8.1-mysqli php8.1-pdo php8.1-xml php8.1-curl rsync \
        openssh-client tar sshpass lftp wget unzip nano gettext-base composer beanstalkd ffmpeg git ca-certificates mysql-client && \
    mkdir -p /opt/mediamtx && \
    wget -qO- https://github.com/bluenviron/mediamtx/releases/download/v1.3.0/mediamtx_v1.3.0_linux_arm64v8.tar.gz | \
        tar xvz -C /opt/mediamtx && \
    chmod +x /opt/mediamtx/mediamtx && \
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
    /opt/mediamtx/mediamtx.yml &&\
    mkdir -p /var/log/supervisor && \
    mkdir ${WORK_DIR}/logs && \
    sed -i \
        -e 's,.*date.timezone =.*,date.timezone = 'Europe/Moscow',g' \
        -e 's,.*date.timezone =.*,date.timezone = 'Europe/Moscow',g' \
        /etc/php/8.1/cli/php.ini && \
    sed -i \
        -e 's,;clear_env = no,clear_env = no,g' \
        -e 's,user =.*,user = root,' \
        -e 's,group =.*,group = root,' \
        /etc/php/8.1/fpm/pool.d/www.conf && \
    [[ ! -z "$(ls -A /etc/nginx/sites-enabled)" ]] || rm /etc/nginx/sites-enabled/* && \
    (crontab -l ; echo "\
*/1 * * * * cd \${WORK_DIR}/server && php cron.php 1\n\
*/5 * * * * cd \${WORK_DIR}/server && php cron.php 5\n\
*/10 * * * * cd \${WORK_DIR}/server && php cron.php 10\n\
*/15 * * * * cd \${WORK_DIR}/server && php cron.php 15\n\
*/30 * * * * cd \${WORK_DIR}/server && php cron.php 30\n\
*/60 * * * * cd \${WORK_DIR}/server && php cron.php 60\n\
*/1 * * * * cd \${WORK_DIR}/server && php main.php\n\
*/1 * * * * cd \${WORK_DIR}/server && php watchdog.php\n\
@reboot cd \${WORK_DIR}/server && php watchdog.php\n\
00 01 * * * cd \${WORK_DIR}/scripts && ./backup.sh\n\
* * * * * cd \${WORK_DIR}/adm && php artisan schedule:run >> /dev/null 2>&1\
") | crontab && \
    envsubst '${WORK_DIR}' < ${WORK_DIR}/.temp/nginx.conf.template > /etc/nginx/conf.d/touchon.conf && \
    rm -rf ${WORK_DIR}/.temp
    
RUN if [ ! -z ${CORE_VER} ] ; then \
    wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} ftp://${FTP_SERVER}/core-release-${CORE_VER}.zip && \
    unzip -q ${WORK_DIR}/core-release-${CORE_VER}.zip -d ${WORK_DIR} >/dev/null 2>&1 && \
    rm ${WORK_DIR}/core-release-${CORE_VER}.zip && \
    composer -n -d ${WORK_DIR}/server clearcache && \
    composer -n -d ${WORK_DIR}/server require workerman/workerman aldas/modbus-tcp-client davidpersson/beanstalk; \
    fi

RUN if [ ! -z ${ADM_VER} ] ; then \
    wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} ftp://${FTP_SERVER}/adm-release-${ADM_VER}.zip && \
    unzip -q ${WORK_DIR}/adm-release-${ADM_VER}.zip -d ${WORK_DIR} >/dev/null 2>&1 && \
    rm ${WORK_DIR}/adm-release-${ADM_VER}.zip && \
    echo '\
APP_NAME="TouchON Admin Panel"\n\
APP_ENV=production\n\
APP_KEY=\n\
APP_DEBUG=true\n\
APP_LOG_LEVEL=debug\n\
APP_TIMEZONE=Europe/Moscow\n\
DEBUGBAR_ENABLED=false\n\
SERVER_FOLDER=${WORK_DIR}/server\n\
IMAGES_BASE_URI=${IMG_MNG_HOST}\n\
DB_CONNECTION=mysql\n\
DB_HOST=${MYSQL_HOST}\n\
DB_PORT=${MYSQL_PORT}\n\
DB_DATABASE=${MYSQL_DATABASE}\n\
DB_USERNAME=${MYSQL_USER}\n\
DB_PASSWORD=${MYSQL_PASSWORD}\n\
BROADCAST_DRIVER=log\n\
CACHE_DRIVER=file\n\
SESSION_DRIVER=file\n\
SESSION_LIFETIME=120\n\
QUEUE_DRIVER=sync' >> ${WORK_DIR}/adm/.env && \
    composer -n -d ${WORK_DIR}/adm clearcache && \
    composer -n -d ${WORK_DIR}/adm install && \
    php ${WORK_DIR}/adm/artisan config:clear && \
    php ${WORK_DIR}/adm/artisan key:generate --force && \
    [[ -L ${WORK_DIR}/adm/storage/app/scripts ]] && rm -rf ${WORK_DIR}/adm/storage/app/scripts && \
    [[ -d ${WORK_DIR}/adm/storage/app/scripts ]] && rm -rf ${WORK_DIR}/adm/storage/app/scripts && \
    [[ -L ${WORK_DIR}/adm/storage/app/scripts ]] || ln -s ${WORK_DIR}/server/userscripts ${WORK_DIR}/adm/storage/app/scripts; \
    fi

CMD printenv > /etc/environment && /usr/bin/supervisord -c ${WORK_DIR}/configs/supervisord.conf
