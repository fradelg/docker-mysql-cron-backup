#!/bin/bash

[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
# If provided, take password from file
[ -z "${MYSQL_PASS_FILE}" ] || { MYSQL_PASS=$(head -1 "${MYSQL_PASS_FILE}"); }
# Alternatively, take it from env var
[ -z "${MYSQL_PASS:=$MYSQL_PASSWORD}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }
[ -z "${GZIP_LEVEL}" ] && { GZIP_LEVEL=6; }

DATE=$(date +%Y%m%d%H%M)
echo "=> Backup started at $(date "+%Y-%m-%d %H:%M:%S")"
DATABASES=${MYSQL_DATABASE:-${MYSQL_DB:-$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)}}
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
    if mysqldump --single-transaction "$MYSQLDUMP_OPTS" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$db" > "$FILENAME"
    then
      EXT=
      if [ -z "${USE_PLAIN_SQL}" ]
      then
        echo "==> Compressing $db with LEVEL $GZIP_LEVEL"
        gzip "-$GZIP_LEVEL" -f "$FILENAME"
        EXT=.gz
        FILENAME=$FILENAME$EXT
        LATEST=$LATEST$EXT
      fi
      BASENAME=$(basename "$FILENAME")
      echo "==> Creating symlink to latest backup: $BASENAME"
      rm "$LATEST" 2> /dev/null
      cd /backup || exit && ln -s "$BASENAME" "$(basename "$LATEST")"
      if [ -n "$MAX_BACKUPS" ]
      then
        while [ "$(find /backup -maxdepth 1 -name "*.$db.sql$EXT" -type f | wc -l)" -gt "$MAX_BACKUPS" ]
        do
          TARGET=$(find /backup -maxdepth 1 -name "*.$db.sql$EXT" -type f | sort | head -n 1)
          echo "==> Max number of ($MAX_BACKUPS) backups reached. Deleting ${TARGET} ..."
          rm -rf "${TARGET}"
          echo "==> Backup ${TARGET} deleted"
        done
      fi
    else
      rm -rf "$FILENAME"
    fi
  fi
done
echo "=> Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"
