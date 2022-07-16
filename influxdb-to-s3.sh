#!/bin/bash

set -e

# Check and set missing environment vars
: "${S3_BUCKET:?"S3_BUCKET env variable is required"}"
if [[ -z ${S3_KEY_PREFIX} ]]; then
  export S3_KEY_PREFIX=""
else
  if [ "${S3_KEY_PREFIX: -1}" != "/" ]; then
    export S3_KEY_PREFIX="${S3_KEY_PREFIX}/"
  fi
fi
: "${INFLUX_BUCKET:?"INFLUX_BUCKET env variable is required"}"
export BACKUP_PATH=${BACKUP_PATH:-/data/influxdb/backup}
export BACKUP_ARCHIVE_PATH=${BACKUP_ARCHIVE_PATH:-${BACKUP_PATH}.tgz}
export DATETIME=$(date "+%Y%m%d%H%M%S")

if [ -z "${S3_ENDPOINT}" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# Add this script to the crontab and start crond
cron() {
  echo "Starting backup cron job with frequency '$1'"
  echo "$1 $0 backup" > /var/spool/cron/crontabs/root
  crond -f
}

# Dump the bucket to a file and push it to S3
backup() {
  # Dump bucket to directory
  echo "Backing up $INFLUX_BUCKET to $BACKUP_PATH"
  if [ -d "$BACKUP_PATH" ]; then
    rm -rf "$BACKUP_PATH"
  fi
  mkdir -p "$BACKUP_PATH"
  influx backup --bucket "$INFLUX_BUCKET" "$BACKUP_PATH"
  if [ $? -ne 0 ]; then
    echo "Failed to backup $INFLUX_BUCKET to $BACKUP_PATH"
    exit 1
  fi

  # Compress backup directory
  if [ -e "$BACKUP_ARCHIVE_PATH" ]; then
    rm -rf "$BACKUP_ARCHIVE_PATH"
  fi
  tar -cvzf "$BACKUP_ARCHIVE_PATH" "$BACKUP_PATH"

  # Push backup file to S3
  echo "Sending file to S3"
  if aws "$AWS_ARGS" s3 rm s3://"${S3_BUCKET}"/${S3_KEY_PREFIX}latest.tgz; then
    echo "Removed latest backup from S3"
  else
    echo "No latest backup exists in S3"
  fi
  if aws "$AWS_ARGS" s3 cp "$BACKUP_ARCHIVE_PATH" s3://"${S3_BUCKET}"/${S3_KEY_PREFIX}latest.tgz; then
    echo "Backup file copied to s3://${S3_BUCKET}/${S3_KEY_PREFIX}latest.tgz"
  else
    echo "Backup file failed to upload"
    exit 1
  fi
  if aws "$AWS_ARGS" s3api copy-object --copy-source "${S3_BUCKET}"/${S3_KEY_PREFIX}latest.tgz --key ${S3_KEY_PREFIX}"${DATETIME}".tgz --bucket "$S3_BUCKET"; then
    echo "Backup file copied to s3://${S3_BUCKET}/${S3_KEY_PREFIX}${DATETIME}.tgz"
  else
    echo "Failed to create timestamped backup"
    exit 1
  fi

  echo "Done"
}

# Handle command line arguments
case "$1" in
  "cron")
    cron "$2"
    ;;
  "backup")
    backup
    ;;
  *)
    echo "Invalid command '$@'"
    echo "Usage: $0 {backup|cron <pattern>}"
esac
