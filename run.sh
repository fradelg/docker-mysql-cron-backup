#!/bin/bash
tail -F /mysql_backup.log &

if [ "${INIT_BACKUP:-0}" -gt "0" ]; then
  echo "=> Create a backup on the startup"
  /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
  echo "=> Restore latest backup"
  until nc -z "$MYSQL_HOST" "$MYSQL_PORT"
  do
      echo "waiting database container..."
      sleep 1
  done
  # Needed to exclude the 'latest.<database>.sql.gz' file, consider only filenames starting with number
  # Only data-tagged backups, eg. '202212250457.database.sql.gz', must be trapped by the regex
  find /backup -maxdepth 1 -name '[0-9]*.*.sql.gz' | sort | tail -1 | xargs /restore.sh
fi

function final_backup {
    echo "=> Captured trap for final backup"
    echo "=> Requested last backup at $(date "+%Y-%m-%d %H:%M:%S")"
    /backup.sh
    exit 0
}

if [ -n "${EXIT_BACKUP}" ]; then
  echo "=> Listening on container shutdown gracefully to make last backup before close"
  trap final_backup SIGHUP SIGINT SIGTERM
fi

touch /HEALTHY.status

echo "${CRON_TIME} /backup.sh >> /mysql_backup.log 2>&1" > /tmp/crontab.conf
crontab /tmp/crontab.conf
echo "=> Running cron task manager in foreground"
crond -f -l 8 -L /mysql_backup.log &

echo "Listening on crond, and wait..."

tail -f /dev/null & wait $!

echo "Script is shutted down."