#!/bin/bash

# Get hostname: try read from file, else get from env
[ -z "${MYSQL_HOST_FILE}" ] || { MYSQL_HOST=$(head -1 "${MYSQL_HOST_FILE}"); }
[ -z "${MYSQL_HOST}" ] && { echo "=> MYSQL_HOST cannot be empty" && exit 1; }
# Get username: try read from file, else get from env
[ -z "${MYSQL_USER_FILE}" ] || { MYSQL_USER=$(head -1 "${MYSQL_USER_FILE}"); }
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
# Get password: try read from file, else get from env, else get from MYSQL_PASSWORD env
[ -z "${MYSQL_PASS_FILE}" ] || { MYSQL_PASS=$(head -1 "${MYSQL_PASS_FILE}"); }
[ -z "${MYSQL_PASS:=$MYSQL_PASSWORD}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }
# Get database name(s): try read from file, else get from env
# Note: when from file, there can be one database name per line in that file
[ -z "${MYSQL_DATABASE_FILE}" ] || { MYSQL_DATABASE=$(cat "${MYSQL_DATABASE_FILE}"); }
# Get level from env, else use 6
[ -z "${GZIP_LEVEL}" ] && { GZIP_LEVEL=6; }

# Get S3 access key/secret: try read from file, else get from env
[ -z "${AWS_ACCESS_KEY_ID_FILE}" ] || { AWS_ACCESS_KEY_ID=$(head -1 "${AWS_ACCESS_KEY_ID_FILE}"); }
[ -z "${AWS_SECRET_ACCESS_KEY_FILE}" ] || { AWS_SECRET_ACCESS_KEY=$(head -1 "${AWS_SECRET_ACCESS_KEY_FILE}"); }
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
[ -z "${S3_REGION}" ] && { S3_REGION=us-east-1; }
export AWS_DEFAULT_REGION="$S3_REGION"
# S3_ENDPOINT allows using S3-compatible services (Cloudflare R2, MinIO, Backblaze B2, ...)
AWS_CLI_OPTS=
[ -n "${S3_ENDPOINT}" ] && AWS_CLI_OPTS="--endpoint-url $S3_ENDPOINT"

upload_to_s3() {
  LOCAL_FILE=$1
  REMOTE_NAME=$2
  S3_URI="s3://${S3_BUCKET}/${S3_PATH:+$S3_PATH/}${REMOTE_NAME}"
  echo "==> Uploading $REMOTE_NAME to $S3_URI"
  # shellcheck disable=SC2086
  if ! aws $AWS_CLI_OPTS s3 cp "$LOCAL_FILE" "$S3_URI" $S3_UPLOAD_OPTS
  then
    echo "==> Failed to upload $REMOTE_NAME to $S3_URI"
  fi
}

DATE=$(date +%Y%m%d%H%M)
echo "=> Backup started at $(date "+%Y-%m-%d %H:%M:%S")"
DATABASES=${MYSQL_DATABASE:-${MYSQL_DB:-$(mariadb -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" $MYSQL_SSL_OPTS -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)}}
for db in ${DATABASES}
do
  if  [[ "$db" != "information_schema" ]] \
      && [[ "$db" != "performance_schema" ]] \
      && [[ "$db" != "mysql" ]] \
      && [[ "$db" != "sys" ]] \
      && [[ "$db" != _* ]]
  then
    echo "==> Dumping database: $db"
    FILENAME=/backup/$DATE.$db.sql
    LATEST=/backup/latest.$db.sql
    BASIC_OPTS="--single-transaction"
    if [ -n "$REMOVE_DUPLICATES" ]
    then
      BASIC_OPTS="$BASIC_OPTS --skip-dump-date"
    fi
    if mariadb-dump $BASIC_OPTS $MYSQLDUMP_OPTS -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" $MYSQL_SSL_OPTS "$db" > "$FILENAME"
    then
      EXT=
      if [ -z "${USE_PLAIN_SQL}" ]
      then
        echo "==> Compressing $db with LEVEL $GZIP_LEVEL"
        gzip "-$GZIP_LEVEL" -n -f "$FILENAME"
        EXT=.gz
        FILENAME=$FILENAME$EXT
        LATEST=$LATEST$EXT
      fi
      BASENAME=$(basename "$FILENAME")
      echo "==> Creating symlink to latest backup: $BASENAME"
      rm "$LATEST" 2> /dev/null
      cd /backup || exit && ln -s "$BASENAME" "$(basename "$LATEST")"
      if [ -n "$S3_BUCKET" ]
      then
        upload_to_s3 "$FILENAME" "$BASENAME"
        upload_to_s3 "$FILENAME" "$(basename "$LATEST")"
      fi
      if [ -n "$REMOVE_DUPLICATES" ]
      then
        echo "==> Removing duplicate database dumps"
        fdupes -idN /backup/
      fi
      if [ -n "$MAX_BACKUPS" ]
      then
        # Execute the delete script, delete older backup or other custom delete script
        /delete.sh "$db" $EXT
      fi
    else
      rm -rf "$FILENAME"
    fi
  fi
done
echo "=> Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"
