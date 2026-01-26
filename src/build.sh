#!/usr/bin/env bash

# 1. Поменять версию
# 2. Заполнить данные FTP сервера
# 3. Указать версии adm и core

source ../.env

# docker buildx rm touchon-builder || true
docker run --privileged --rm tonistiigi/binfmt --install all

docker buildx create \
    --use \
    --name touchon-builder \
    --driver docker-container

DOCKER_BUILDKIT=1 docker buildx build \
    --progress=plain \
    --builder touchon-builder \
    --provenance false \
    --platform linux/arm/v7,linux/arm64,linux/amd64 \
    -t dhub.touchon.tech/touchon-v1:${VER} \
    --build-arg FTP_SERVER=${FTP_SERVER} \
    --build-arg FTP_USER=${FTP_USER} \
    --build-arg FTP_PASSWORD=${FTP_PASSWORD} \
    --build-arg ADM_VER=${ADM_VER} \
    --build-arg CORE_VER=${CORE_VER} \
    --push \
    .