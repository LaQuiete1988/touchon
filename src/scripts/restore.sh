#!/usr/bin/env bash


remoteArchiveDownload()
{
	echo "No local $2 backups found"
	[ -d ${WORK_DIR}/backups/$1/$2 ] || mkdir -p ${WORK_DIR}/backups/$1/$2
	scp -P ${SSH_PORT} -o StrictHostKeyChecking=no -i ${WORK_DIR}/ssh/id_rsa \
        ${SSH_USER}@${SSH_SERVER}:${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1/$2.tar.gz ${WORK_DIR}/backups/$1
	tar zxf ${WORK_DIR}/backups/$1/$2.tar.gz -C ${WORK_DIR}/backups/$1/$2
	rm ${WORK_DIR}/backups/$1/$2.tar.gz
	echo "> $2 backups downloaded"
}

databaseRestore()
{
    if [[ ! -d ${WORK_DIR}/backups/$1/db ]] || [[ ! $(ls -A ${WORK_DIR}/backups/$1/db) ]]; then
		remoteArchiveDownload $1 db
	else
		echo "Local database backups found"
	fi

	admBackupVersion=$(cat ${WORK_DIR}/backups/daily/db/adm_version.txt | grep 'ADM' | awk '{printf $3}')
	# if [[ -f ${WORK_DIR}/adm/readme.md ]]; then
    #     admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/readme.md)
    # else
    #     admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/README.MD)
    # fi

	# if [[ ! -d ${WORK_DIR}/adm ]] || [[ "$admBackupVersion" != "$admCurrentVersion" ]]; then
		
	echo "Download adm ver $admBackupVersion"
	[ -d ${WORK_DIR}/adm ] && mv ${WORK_DIR}/adm ${WORK_DIR}/adm.bak
				
	wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} \
    	ftp://${FTP_SERVER}/adm-release-$admBackupVersion.zip
    unzip -q ${WORK_DIR}/adm-release-$admBackupVersion.zip -d ${WORK_DIR} >/dev/null 2>&1
    rm ${WORK_DIR}/adm-release-$admBackupVersion.zip

# Очищаем БД
   	mysql -uroot -p${MYSQL_ROOT_PASSWORD} << EOF
DROP DATABASE IF EXISTS $MYSQL_DATABASE;
CREATE DATABASE $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOF

# Пишем нужные переменные в .env
    cat << EOF > ${WORK_DIR}/adm/.env
APP_NAME="TouchON Admin Panel"
APP_ENV=production
APP_KEY=
APP_DEBUG=true
APP_LOG_LEVEL=debug
APP_URL=http://localhost
APP_TIMEZONE=Europe/Moscow
DEBUGBAR_ENABLED=false
SERVER_FOLDER=${WORK_DIR}/server
IMAGES_BASE_URI=${IMG_MNG_HOST}
DB_CONNECTION=mysql
DB_HOST=${MYSQL_HOST}
DB_PORT=${MYSQL_PORT}
DB_DATABASE=${MYSQL_DATABASE}
DB_USERNAME=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}
BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
QUEUE_DRIVER=sync
EOF

	composer -n -d ${WORK_DIR}/adm install

    php ${WORK_DIR}/adm/artisan config:clear
    php ${WORK_DIR}/adm/artisan key:generate --force

# Добавляем симлинк на каталог пользовательских скриптов
	[[ -d ${WORK_DIR}/adm/storage/app/scripts ]] && rm -rf ${WORK_DIR}/adm/storage/app/scripts
	[[ -L ${WORK_DIR}/adm/storage/app/scripts ]] || ln -s ${WORK_DIR}/server/userscripts ${WORK_DIR}/adm/storage/app/scripts

	gunzip < ${WORK_DIR}/backups/$1/db/db_backup.sql.gz | \
		mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
	
	if [[ -f ${WORK_DIR}/adm/readme.md ]]; then
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/readme.md)
    else
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/README.MD)
    fi
    echo "[OK] Adm ver.$admCurrentVersion has been installed"
}

userscriptsRestore()
{
	if [[ ! -d ${WORK_DIR}/backups/$1/userscripts ]] || [[ ! $(ls -A ${WORK_DIR}/backups/$1/userscripts) ]]; then
        remoteArchiveDownload $1 userscripts
    else
        echo "Backups are storing locally"
    fi

	coreBackupVersion=$(cat ${WORK_DIR}/backups/daily/userscripts/core_version.txt | grep 'CORE' | awk '{printf $3}')
		
	echo "Download core ver $coreBackupVersion"
	if [[ -d ${WORK_DIR}/server ]]; then
		php ${WORK_DIR}/server/server.php stop -g
		mv ${WORK_DIR}/server ${WORK_DIR}/server.bak
	fi
	# source core_installation.sh $coreBackupVersion
	wget -P ${WORK_DIR} -r -nd --user=${FTP_USER} --password=${FTP_PASSWORD} \
    	ftp://${FTP_SERVER}/core-release-$coreBackupVersion.zip
    unzip -q ${WORK_DIR}/core-release-$coreBackupVersion.zip -d ${WORK_DIR} >/dev/null 2>&1
    rm ${WORK_DIR}/core-release-$coreBackupVersion.zip

    sed -i "s/\$host =.*/\$host = getenv(\'MYSQL_HOST\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbname =.*/\$dbname = getenv(\'MYSQL_DATABASE\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbuser =.*/\$dbuser = getenv(\'MYSQL_USER\');/g" ${WORK_DIR}/server/include.php
    sed -i "s/\$dbpass =.*/\$dbpass = getenv(\'MYSQL_PASSWORD\');/g" ${WORK_DIR}/server/include.php
    sed -i 's/php -f thread.php/cd \".ROOT_DIR.\" \&\& php -f thread.php/' ${WORK_DIR}/server/classes/SendSocket.php

    php ${WORK_DIR}/server/server.php start -d

    if [[ -f ${WORK_DIR}/server/readme.md ]]; then
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/readme.md)
    else
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/README.MD)
    fi
    echo "[OK] Core ver.$coreCurrentVersion installed"

	cp -r ${WORK_DIR}/backups/$1/userscripts/userscripts/* ${WORK_DIR}/server/userscripts
}

controllerRestore()
{
    if [[ ! -d ${WORK_DIR}/backups/$1/controllers ]] || [[ ! $(ls -A ${WORK_DIR}/backups/$1/controllers) ]]; then
        remoteArchiveDownload $1 controllers
    else
        echo "Backups are storing locally"
    fi

	localIp=$(ip a | grep eth0:2 | awk '/inet/ {print $2}' | cut -d/ -f1)
	
	ctrIps=$(php ${WORK_DIR}/scripts/megad-cfg-2561.php --scan --local-ip $localIp)
	PS3="Choose a controller to restore config: "
	select ctr in $ctrIps
	do
		ctrToRestore=$ctr
	break
	done

	cfgFiles=$(ls ${WORK_DIR}/backups/daily/controllers)
	PS3="Choose a config file: "
	select cfg in $cfgFiles
	do
		cfgToRestore=$cfg
	break
	done

	while true; do
    	read -p "Do you want to write config file $cfgToRestore to controller $ctrToRestore? y/N " yn
    	case $yn in
        	[Yy]* ) php ${WORK_DIR}/scripts/megad-cfg-2561.php --ip $ctrToRestore \
				--write-conf ${WORK_DIR}/backups/$1/controllers/$cfgToRestore -p sec; break;;
        	[Nn]* ) exit;;
        	* ) exit;;
    	esac
	done
}

usage()
{
	echo ""
	echo "Usage: ./restore.sh [OPTION] [ARGUMENT]"
	echo ""
	echo "Available options:"
	echo "-s, -u        server and userscripts restore"
	echo "-d, -a        adm and database restore"
	echo "-c            controllers restore"
	echo ""
	echo "Available arguments:"
	echo "daily         restore daily backup"
	echo "weekly        restore weekly backup"
	echo ""
	echo "Examples:"
	echo "./restore -d daily"
	echo "./restore -c weekly"
}

function check_arg(){
	if [[ $2 == -* ]]; then 
		echo "Option $1 requires an argument" >&2
		usage
		exit 2
    elif [[ ! $2 =~ ^(daily|weekly)$ ]]; then
        echo "Option $1 requires an argument: daily or weekly" >&2
		usage
		exit 2
	fi
}
 
function parse_param()
{
	if [ -z "$1" ];then
		echo "Empty list of options" >&2
		usage
		exit 2
	fi
	while getopts ":s:u:a:d:c:" opt; do
		case $opt in
		s)
			check_arg "-s" "$OPTARG"
            userscriptsRestore $OPTARG
		;;
		u)
			check_arg "-u" "$OPTARG"
            userscriptsRestore $OPTARG
		;;
		d)
            check_arg "-d" "$OPTARG"
			databaseRestore $OPTARG
		;;
		a)
            check_arg "-a" "$OPTARG"
			databaseRestore $OPTARG
		;;
		c)
            check_arg "-c" "$OPTARG"
			controllerRestore $OPTARG
		;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			exit 2
		;;
		:)
			echo "Option -$OPTARG requires an argument" >&2
			usage
			exit 2
		;;
		esac
	done
}

parse_param "$@"