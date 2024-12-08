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

DATE=$(date +%Y%m%d%H%M)
echo "=> Backup started at $(date "+%Y-%m-%d %H:%M:%S")"
DATABASES=${MYSQL_DATABASE:-${MYSQL_DB:-$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" $MYSQL_SSL_OPTS -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)}}
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
    if mysqldump --single-transaction --skip-dump-date $MYSQLDUMP_OPTS -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" $MYSQL_SSL_OPTS "$db" > "$FILENAME"
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
      if [ -n "$REMOVE_DUPLICATES" ]
      then
        echo "=> Removing duplicate database dumps"
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
