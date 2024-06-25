#!/usr/bin/env bash

docker-compose up -d --build
docker exec touchon bash -c 'php ${WORK_DIR}/adm/artisan migrate --seed --force'
docker exec touchon bash -c 'php ${WORK_DIR}/adm/artisan create:user superadmin ${ADM_SUPERADMIN_USER} ${ADM_SUPERADMIN_PASSWORD}'
docker exec touchon bash -c 'php ${WORK_DIR}/adm/artisan create:user superadmin ${ADM_PARTNER_USER} ${ADM_PARTNER_PASSWORD}'
containerId=$(docker ps -aqf "name=touchon")
docker commit $containerId touchon:1.1-jethome
docker tag touchon:1.1-jethome 178.57.106.190:5000/touchon:1.1-jethome
docker push 178.57.106.190:5000/touchon:1.1-jethome
