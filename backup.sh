#!/bin/bash
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
[ -z "${MYSQL_PASS:=$MYSQL_PASSWORD}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }

DATE=$(date +%Y%m%d%H%M)
echo "=> Backup started at $(date "+%Y-%m-%d %H:%M:%S")"
DATABASES=${MYSQL_DATABASE:-${MYSQL_DB:-$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)}}
DB_COUNTER=0
for db in ${DATABASES}
do
  if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]]
  then
    echo "==> Dumping database: $db"
    FILENAME=/backup/$DATE.$db.sql
    LATEST=/backup/latest.$db.sql.gz
    if mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" --databases "$db" $MYSQLDUMP_OPTS > "$FILENAME"
    then
      gzip -f "$FILENAME"
      echo "==> Creating symlink to latest backup: $(basename "$FILENAME".gz)"
      rm "$LATEST" 2> /dev/null
      cd /backup && ln -s $(basename "$FILENAME".gz) $(basename "$LATEST") && cd -
      DB_COUNTER=$(( DB_COUNTER + 1 ))
    else
      rm -rf "$FILENAME"
    fi
  fi
done

if [ -n "$MAX_BACKUPS" ]
then
  MAX_FILES=$(( MAX_BACKUPS * DB_COUNTER ))
  while [ "$(find /backup -maxdepth 1 -name "*.sql.gz" -type f | wc -l)" -gt "$MAX_FILES" ]
  do
    TARGET=$(find /backup -maxdepth 1 -name "*.sql.gz" -type f | sort | head -n 1)
    echo "==> Max number of backups ($MAX_BACKUPS) reached. Deleting ${TARGET} ..."
    rm -rf "${TARGET}"
    echo "==> Backup ${TARGET} deleted"
  done
fi

echo "=> Backup process finished at $(date "+%Y-%m-%d %H:%M:%S")"
