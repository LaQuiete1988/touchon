#!/usr/bin/env bash

# 1. Поменять версию
# 2. Заполнить данные FTP сервера
# 3. Указать версии adm и core

source ../.env

DOCKER_BUILDKIT=1 docker build \
    -t ${REGISTRY}/touchon:${VER}-jethome \
    --build-arg FTP_SERVER=${FTP_SERVER} \
    --build-arg FTP_USER=${FTP_USER} \
    --build-arg FTP_PASSWORD=${FTP_PASSWORD} \
    --build-arg ADM_VER=${ADM_VER} \
    --build-arg CORE_VER=${CORE_VER} \
    --no-cache \
    .
docker push ${REGISTRY}/touchon:${VER}-jethome
