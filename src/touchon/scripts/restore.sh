#!/usr/bin/env bash


remoteArchiveDownload()
{
	echo "No local $2 backups found"
	[ -d ${SSH_SOURCE_DIR}/$1/$2 ] || mkdir -p ${SSH_SOURCE_DIR}/$1/$2
	scp -P ${SSH_PORT} -o StrictHostKeyChecking=no -i ${WORK_DIR}/ssh/id_rsa \
        ${SSH_USER}@${SSH_SERVER}:${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1/$2.tar.gz ${SSH_SOURCE_DIR}/$1
	tar zxf ${SSH_SOURCE_DIR}/$1/$2.tar.gz -C ${SSH_SOURCE_DIR}/$1/$2
	rm ${SSH_SOURCE_DIR}/$1/$2.tar.gz
	echo "> $2 backups downloaded"
}

databaseRestore()
{
    if [[ ! -d ${SSH_SOURCE_DIR}/$1/db ]] || [[ ! $(ls -A ${SSH_SOURCE_DIR}/$1/db) ]]; then
		remoteArchiveDownload $1 db
	else
		echo "Local database backups found"
	fi

	admBackupVersion=$(cat ${SSH_SOURCE_DIR}/daily/db/adm_version.txt | grep 'ADM' | awk '{printf $3}')
	if [[ -f ${WORK_DIR}/adm/readme.md ]]; then
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/readme.md)
    else
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/README.MD)
    fi

	if [[ ! -d ${WORK_DIR}/adm ]] || [[ "$admBackupVersion" != "$admCurrentVersion" ]]; then
		
			echo "Download adm ver $admBackupVersion"
			[ -d ${WORK_DIR}/adm ] && mv ${WORK_DIR}/adm ${WORK_DIR}/adm.bak
			source adm_installation.sh $admBackupVersion
	fi

	gunzip < ${SSH_SOURCE_DIR}/daily/db/db_backup.sql.gz | \
		mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
}

userscriptsRestore()
{
	if [[ ! -d ${SSH_SOURCE_DIR}/$1/userscripts ]] || [[ ! $(ls -A ${SSH_SOURCE_DIR}/$1/userscripts) ]]; then
        remoteArchiveDownload $1 userscripts
    else
        echo "Backups are storing locally"
    fi

	coreBackupVersion=$(cat ${SSH_SOURCE_DIR}/daily/userscripts/core_version.txt | grep 'CORE' | awk '{printf $3}')
	if [[ -f ${WORK_DIR}/server/readme.md ]]; then
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/readme.md)
    else
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/README.MD)
    fi
	
	if [[ ! -d ${WORK_DIR}/server ]] || [[ "$coreBackupVersion" != "$coreCurrentVersion" ]]; then
		
			echo "Download core ver $coreBackupVersion"
			[ -d ${WORK_DIR}/server ] && mv ${WORK_DIR}/server ${WORK_DIR}/server.bak
			source core_installation.sh $coreBackupVersion
	fi

	cp -r ${SSH_SOURCE_DIR}/$1/userscripts/userscripts/* ${WORK_DIR}/server/userscripts
}

controllerRestore()
{
    if [[ ! -d ${SSH_SOURCE_DIR}/$1/controllers ]] || [[ ! $(ls -A ${SSH_SOURCE_DIR}/$1/controllers) ]]; then
        remoteArchiveDownload $1 controllers
    else
        echo "Backups are storing locally"
    fi

	localIp=$(ip a | grep eth0:2 | awk '/inet/ {print $2}' | cut -d/ -f1)
	
	ctrIps=$(php /opt/touchon/scripts/megad-cfg-2561.php --scan --local-ip $localIp)
	PS3="Choose a controller to restore config: "
	select ctr in $ctrIps
	do
		ctrToRestore=$ctr
	break
	done

	cfgFiles=$(ls /opt/touchon/workdir/backups/daily/controllers)
	PS3="Choose a config file: "
	select cfg in $cfgFiles
	do
		cfgToRestore=$cfg
	break
	done

	while true; do
    	read -p "Do you want to write config file $cfgToRestore to controller $ctrToRestore? y/N " yn
    	case $yn in
        	[Yy]* ) php /opt/touchon/scripts/megad-cfg-2561.php --ip $ctrToRestore \
				--write-conf ${SSH_SOURCE_DIR}/$1/controllers/$cfgToRestore -p sec; break;;
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