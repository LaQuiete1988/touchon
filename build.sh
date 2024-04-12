#!/usr/bin/env bash

docker-compose up -d --build
docker-compose exec -ti touchon /opt/touchon/scripts/dependent_startup.sh
containerId=$(docker ps -aqf "name=touchon")
docker commit $containerId touchon:1.0-jethome
docker tag touchon:1.0-jethome 178.57.106.190:5000/touchon:1.0-jethome
docker push 178.57.106.190:5000/touchon:1.0-jethome
