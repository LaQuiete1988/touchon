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
    && mkdir -p /opt/mediamtx \
    && wget -qO- https://github.com/bluenviron/mediamtx/releases/download/v1.3.0/mediamtx_v1.3.0_linux_arm64v8.tar.gz | \
        tar xvz -C /opt/mediamtx \
    && chmod +x /opt/mediamtx/mediamtx \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    && mkdir ${WORK_DIR}/logs

COPY ./configs configs
COPY --chmod=0775 ./scripts scripts

CMD /usr/bin/supervisord -c ${WORK_DIR}/configs/supervisord.conf