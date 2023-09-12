#!/usr/bin/env bash

if [[ ! -d ${WORK_DIR}/ssh ]]; then
    mkdir -p ${WORK_DIR}/ssh
fi

if [[ -f ${WORK_DIR}/ssh/id_rsa ]]; then
    rm ${WORK_DIR}/ssh/*
fi

ssh-keygen -b 2048 -t rsa -f ${WORK_DIR}/ssh/id_rsa -q -N '' -C ${SSH_CLIENT_DIR}
sshpass -p ${SSH_SERVER_PASSWORD} ssh -o StrictHostKeyChecking=no -i ${WORK_DIR}/ssh/id_rsa \
    ${SSH_USER}@${SSH_SERVER} -p ${SSH_PORT} "sed -i /${SSH_CLIENT_DIR}/d ~/.ssh/authorized_keys"
cat ${WORK_DIR}/ssh/id_rsa.pub | sshpass -p ${SSH_SERVER_PASSWORD} \
    ssh -o StrictHostKeyChecking=no -i ${WORK_DIR}/ssh/id_rsa \
    ${SSH_USER}@${SSH_SERVER} -p ${SSH_PORT} 'cat >> ~/.ssh/authorized_keys'
