#!/usr/bin/env bash                                                                                                                                                                                                                                                                                                                       back>

function userscriptsBackup ()
{
    rsync -azh --delete ${WORK_DIR}/server/userscripts ${WORK_DIR}/backups/daily/userscripts
    if [ $? -eq 0 ]; then
            echo "$(date +'%b %d %H:%M:%S')  Backup [OK] Userscripts daily backup succeeded." \
                >> /var/log/cron.log
        else
            echo "$(date +'%b %d %H:%M:%S')  Backup [ERROR] Userscripts daily backup failed." \
                >> /var/log/cron.log
        fi
}


function dbBackup ()
{
    if [[ ! -d ${WORK_DIR}/backups/daily/db ]]; then
        mkdir -p ${WORK_DIR}/backups/daily/db
    fi

    mysqldump --host=${MYSQL_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
        | gzip > ${WORK_DIR}/backups/daily/db/db_backup.sql.gz

    if [[ -f ${WORK_DIR}/backups/daily/db/db_backup.sql.gz ]]; then
        echo "$(date +'%b %d %H:%M:%S')  MySQL [OK] DB daily backup is succeeded" >> /var/log/cron.log
    else
        echo "$(date +'%b %d %H:%M:%S')  MySQL [ERROR] DB daily backup failed" >> /var/log/cron.log
    fi
}


function versionsBackup ()
{
    if [[ ! -d ${WORK_DIR}/backups/daily/db ]]; then
        mkdir -p ${WORK_DIR}/backups/daily/db
    fi

    if [[ ! -d ${WORK_DIR}/backups/daily/userscripts ]]; then
        mkdir -p ${WORK_DIR}/backups/daily/userscripts
    fi

    if [[ -f ${WORK_DIR}/server/readme.md ]]; then
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/readme.md)
    else
        coreCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/server/README.MD)
    fi

    if [[ -f ${WORK_DIR}/adm/readme.md ]]; then
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/readme.md)
    else
        admCurrentVersion=$(sed -n '/.*ver /s///p' < ${WORK_DIR}/adm/README.MD)
    fi

    if [[ ! -f ${WORK_DIR}/backups/daily/db/adm_version.txt ]]; then
        touch ${WORK_DIR}/backups/daily/db/adm_version.txt
    else
        admBackupVersion=$(cat ${WORK_DIR}/backups/daily/db/adm_version.txt | grep 'ADM' | awk '{printf $3}')
    fi

    if [[ ! -f ${WORK_DIR}/backups/daily/userscripts/core_version.txt ]]; then
        touch ${WORK_DIR}/backups/daily/userscripts/core_version.txt
    else
        coreBackupVersion=$(cat ${WORK_DIR}/backups/daily/userscripts/core_version.txt | grep 'CORE' | awk '{printf $3}')
    fi

    if [[ "$coreBackupVersion" != "$coreCurrentVersion" ]]; then 
        echo -e "CORE version $coreCurrentVersion" > ${WORK_DIR}/backups/daily/userscripts/core_version.txt
        echo "$(date +'%b %d %H:%M:%S')  Backup [OK] Core version updated." \
                >> /var/log/cron.log
    fi

    if [[ "$admBackupVersion" != "$admCurrentVersion" ]]; then 
        echo -e "ADM version $admCurrentVersion" > ${WORK_DIR}/backups/daily/db/adm_version.txt
        echo "$(date +'%b %d %H:%M:%S')  Backup [OK] Adm version updated." \
                >> /var/log/cron.log
    fi
}

controllersBackup()
{
    if [[ ! -d ${WORK_DIR}/backups/daily/controllers ]]; then
        mkdir -p ${WORK_DIR}/backups/daily/controllers
    fi

    ipString=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -se "SELECT ip_address FROM $MYSQL_DATABASE.devices WHERE type=1 AND active=1;")
    ip_array=($ipString)

    # echo "Array size: ${#ip_array[*]}"

    for (( i=0; i < ${#ip_array[*]}; i++ ))
    do
        echo ${ip_array[i]}
        php ${WORK_DIR}/scripts/megad-cfg-2561.php \
            --ip ${ip_array[i]} --read-conf ${WORK_DIR}/backups/daily/controllers/${ip_array[i]}.cfg \
            -p sec --local-ip $(ip -4 addr show dev eth0 | grep eth0:2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    done
}

mikrotikBackup()
{
    if [[ ! -d ${WORK_DIR}/backups/daily/mikrotik ]]; then
        mkdir -p ${WORK_DIR}/backups/daily/mikrotik
    fi

    # Add "; export file=mikrotik.rsc hide-sensitive" to a mikrotik command to save a .rsc backup file. 
    sshpass -p ${MIKROTIK_PASSWORD} ssh -o StrictHostKeyChecking=no ${MIKROTIK_USER}@${MIKROTIK_IP} \
        "/system backup save name=mikrotik" 
    sshpass -p ${MIKROTIK_PASSWORD} scp -o StrictHostKeyChecking=no \
        ${MIKROTIK_USER}@${MIKROTIK_IP}:mikrotik.backup ${WORK_DIR}/backups/daily/mikrotik
    # Uncomment to get a .rsc backup file from a device.
    # sshpass -p ${MIKROTIK_PASSWORD} scp -o StrictHostKeyChecking=no \
    #     ${MIKROTIK_USER}@${MIKROTIK_IP}:mikrotik.rsc ${WORK_DIR}/backups/daily/mikrotik

}

# $1 - daily or weekly
userscriptsTarToRemote()
{
    tar zcvf - -C ${WORK_DIR}/backups/$1/userscripts . | ssh ${SSH_USER}@${SSH_SERVER} -p ${SSH_PORT} -i ${WORK_DIR}/ssh/id_rsa \
        "[ -d ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 ] || mkdir -p ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 \
        && cat > ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1/userscripts.tar.gz"

    if [ $? -eq 0 ]; then
        echo "$(date +'%b %d %H:%M:%S')  Backup [OK] Userscripts $1 backup syncronization with BackupServer succeeded." \
            >> /var/log/cron.log
    else
        echo "$(date +'%b %d %H:%M:%S')  Backup [ERROR] Userscripts $1 backup syncronization with BackupServer failed." \
            >> /var/log/cron.log
    fi
}

# $1 - daily or weekly
dbTarToRemote()
{
    tar zcvf - -C ${WORK_DIR}/backups/$1/db . | \
        ssh ${SSH_USER}@${SSH_SERVER} -p ${SSH_PORT} -i ${WORK_DIR}/ssh/id_rsa \
        "[ -d ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 ] || mkdir ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 \
        && cat > ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1/db.tar.gz"

    if [ $? -eq 0 ]; then
        echo "$(date +'%b %d %H:%M:%S')  Backup [OK] DB $1 backup syncronization with BackupServer succeeded." \
            >> /var/log/cron.log
    else
        echo "$(date +'%b %d %H:%M:%S')  Backup [ERROR] DB $1 backup syncronization with BackupServer failed." \
            >> /var/log/cron.log
    fi
}

controllersTarToRemote()
{
    tar zcvf - -C ${WORK_DIR}/backups/$1/controllers . | \
        ssh ${SSH_USER}@${SSH_SERVER} -p ${SSH_PORT} -i ${WORK_DIR}/ssh/id_rsa \
        "[ -d ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 ] || mkdir ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 \
        && cat > ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1/controllers.tar.gz"

    if [ $? -eq 0 ]; then
        echo "$(date +'%b %d %H:%M:%S')  Backup [OK] Controllers $1 backup syncronization with BackupServer succeeded." \
            >> /var/log/cron.log
    else
        echo "$(date +'%b %d %H:%M:%S')  Backup [ERROR] Controllers $1 backup syncronization with BackupServer failed." \
            >> /var/log/cron.log
    fi
}

mikrotikTarToRemote()
{
    tar zcvf - -C ${WORK_DIR}/backups/$1/mikrotik . | \
        ssh ${SSH_USER}@${SSH_SERVER} -p ${SSH_PORT} -i ${WORK_DIR}/ssh/id_rsa \
        "[ -d ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 ] || mkdir ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1 \
        && cat > ${SSH_BACKUP_DIR}/${SSH_CLIENT_DIR}/$1/mikrotik.tar.gz"

    if [ $? -eq 0 ]; then
        echo "$(date +'%b %d %H:%M:%S')  Backup [OK] Mikrotik $1 backup syncronization with BackupServer succeeded." \
            >> /var/log/cron.log
    else
        echo "$(date +'%b %d %H:%M:%S')  Backup [ERROR] Mikrotik $1 backup syncronization with BackupServer failed." \
            >> /var/log/cron.log
    fi
}

if [[ ! -d ${WORK_DIR}/backups/daily ]]; then
    mkdir -p ${WORK_DIR}/backups/daily
fi

if [[ ! -d ${WORK_DIR}/backups/weekly ]]; then
    mkdir -p ${WORK_DIR}/backups/weekly
fi

if [[ "${SSH_CLIENT_DIR:-unset}" == "unset" ]]; then
    
    echo "$(date +'%b %d %H:%M:%S')  Backup [ERROR] SSH_CLIENT_DIR variable in .env file is not set." \
        >> /var/log/cron.log

else

    userscriptsBackup
    versionsBackup
    dbBackup
    controllersBackup
    mikrotikBackup

    userscriptsTarToRemote daily
    dbTarToRemote daily
    controllersTarToRemote daily
    mikrotikTarToRemote daily

    if [[ ! $(ls ${WORK_DIR}/backups/weekly) ]] || [[ $(date +'%u') == 1 ]]; then
        cp -r ${WORK_DIR}/backups/daily/* ${WORK_DIR}/backups/weekly
        userscriptsTarToRemote weekly
        dbTarToRemote weekly
        controllersTarToRemote weekly
        mikrotikTarToRemote weekly
    fi

fi
