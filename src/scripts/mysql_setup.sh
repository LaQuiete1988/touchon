#!/usr/bin/env bash

mysql -uroot -p$MYSQL_ROOT_PASSWORD << EOF
DROP USER IF EXISTS 'smarthome'@'localhost';
CREATE USER 'smarthome'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON smarthome.* TO 'smarthome'@'localhost';
CREATE USER IF NOT EXISTS 'dbadmin'@'localhost' IDENTIFIED VIA pam;
GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'localhost' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS ''@'localhost' IDENTIFIED WITH pam;
GRANT ALL PRIVILEGES ON smarthome.* TO ''@'localhost';
CREATE DATABASE IF NOT EXISTS smarthome CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOF

