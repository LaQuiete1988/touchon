ARG UBUNTU_VERSION

FROM ubuntu:${UBUNTU_VERSION}

ARG WORK_DIR
ARG EXTRA_PACKAGES
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB.UTF-8
ENV LC_ALL=en_GB.UTF-8

WORKDIR ${WORK_DIR}

RUN apt-get update \ 
    && apt-get install -y --no-install-recommends --no-install-suggests locales locales-all \
    && apt-get install -y --no-install-recommends --no-install-suggests supervisor nginx tzdata mariadb-server \
    mariadb-client iputils-ping cron php-fpm php-bcmath php-mbstring php-mysqli php-pdo php-xml php-curl rsync \
    openssh-client tar sshpass lftp wget unzip nano gettext-base composer beanstalkd ffmpeg ${EXTRA_PACKAGES} \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    && echo "export SERVER_LOCAL_IP=\$(ip -4 addr show dev eth0 | grep eth0:1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')" >> ~/.bashrc

CMD /usr/bin/supervisord -c ${WORK_DIR}/configs/supervisord.conf