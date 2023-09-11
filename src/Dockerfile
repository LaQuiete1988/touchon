FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB.UTF-8
ENV LC_ALL=en_GB.UTF-8
WORKDIR /opt/touchon

COPY ./touchon /opt/touchon

RUN apt-get update \ 
    && apt-get install -y --no-install-recommends --no-install-suggests locales locales-all \
    && apt-get install -y --no-install-recommends --no-install-suggests supervisor nginx tzdata mariadb-server \
    mariadb-client iputils-ping cron php7.4-fpm php7.4-bcmath php7.4-mbstring php7.4-mysqli php7.4-pdo php7.4-xml php7.4-curl rsync \
    openssh-client tar sshpass lftp wget unzip nano gettext-base composer \
    && apt-get install -y --no-install-recommends --no-install-suggests git ca-certificates \
    && sed -i 's,;clear_env = no,clear_env = no,g' /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i 's,user =.*,user = root,' /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i 's,group =.*,group = root,' /etc/php/7.4/fpm/pool.d/www.conf \
    && crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php cron.php 1'; } | crontab - \
    && crontab -l | { cat; echo '*/5 * * * * cd ${WORK_DIR}/server && php cron.php 5'; } | crontab - \
    && crontab -l | { cat; echo '*/10 * * * * cd ${WORK_DIR}/server && php cron.php 10'; } | crontab - \
    && crontab -l | { cat; echo '*/15 * * * * cd ${WORK_DIR}/server && php cron.php 15'; } | crontab - \
    && crontab -l | { cat; echo '*/30 * * * * cd ${WORK_DIR}/server && php cron.php 30'; } | crontab - \
    && crontab -l | { cat; echo '*/60 * * * * cd ${WORK_DIR}/server && php cron.php 60'; } | crontab - \
    && crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php main.php'; } | crontab - \
    && crontab -l | { cat; echo '00 01 * * * cd /opt/touchon/scripts && ./backup.sh'; } | crontab - \
    && crontab -l | { cat; echo '*/1 * * * * cd ${WORK_DIR}/server && php watchdog.php'; } | crontab - \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    && chmod +x /opt/touchon/scripts/* && chmod +x /opt/touchon/scripts/rs_control/rs_control \
    && ln -s /opt/touchon/scripts/rs_control/rs_control /usr/bin/rs_control

CMD ["/usr/bin/supervisord", "-c", "/opt/touchon/configs/supervisord.conf"]
