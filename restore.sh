#!/bin/bash
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
[ -z "${MYSQL_PASS}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }

if [ "$#" -ne 1 ]
then
    echo "You must pass the path of the backup file to restore"
fi

echo "=> Restore database from $1"
set -o pipefail
DB_NAME=${MYSQL_DATABASE:-${MYSQL_DB}}
if gunzip --stdout "$1" | mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$DB_NAME"
then
    echo "=> Restore succeeded"
else
    echo "=> Restore failed"
fi
