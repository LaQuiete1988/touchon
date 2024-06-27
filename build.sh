#!/usr/bin/env bash

docker-compose up -d --build
containerId=$(docker ps -aqf "name=touchon")
docker commit $containerId touchon:1.1-jethome
docker tag touchon:1.1-jethome 178.57.106.190:5000/touchon:1.1-jethome
docker push 178.57.106.190:5000/touchon:1.1-jethome
