#!/usr/bin/env bash

docker-compose up -d --build
docker-compose exec -ti touchon /opt/touchon/scripts/dependent_startup.sh
#containerId=$(docker ps -aqf "name=touchon")
#docker commit $containerId touchon:1.1-jethome
#docker tag touchon:1.1-jethome 10.35.99.172:5000/touchon:1.1-jethome
#docker push 10.35.99.172:5000/touchon:1.1-jethome
