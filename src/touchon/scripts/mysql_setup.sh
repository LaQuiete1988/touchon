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
FLUSH PRIVILEGES;
EOF
fi
