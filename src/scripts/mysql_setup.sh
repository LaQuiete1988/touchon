#!/usr/bin/env bash

mysql -uroot -e "exit" &> /dev/null
if [[ $? == 0 ]]; then
  mysql -uroot << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
fi

if [[ $(mysql -uroot -p${MYSQL_ROOT_PASSWORD} -se "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${MYSQL_USER}');") != 1 ]]; then
   mysql -uroot -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
fi

mysql -uroot -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOF