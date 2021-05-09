#!/bin/bash
set -eu pipefail

BASE_DIR=/tmp/letsencrypt
WORK_DIR=${BASE_DIR}/work
LOGS_DIR=${BASE_DIR}/logs
CONFIG_DIR=${BASE_DIR}/config

mkdir -p ${WORK_DIR} ${LOGS_DIR} ${CONFIG_DIR} 

certbot certonly \
    --dns-route53 \
    --agree-tos \
    --work-dir ${WORK_DIR} \
    --logs-dir ${LOGS_DIR} \
    --config-dir ${CONFIG_DIR} \
    -n \
    -d "*.${DOMAIN}" -d ${DOMAIN} \
    -m ${EMAIL}

aws s3 sync ${CONFIG_DIR}/live/${DOMAIN} s3://${BUCKET}/current/
