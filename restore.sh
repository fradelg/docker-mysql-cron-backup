#!/bin/bash
[ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
[ -z "${MYSQL_PASS}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }

if [ "$#" -ne 1 ]
then
    echo "You must pass the path of the backup file to restore"
fi

set -o pipefail

SQL=$(gunzip -c "$1")
DB_NAME=${MYSQL_DATABASE:-${MYSQL_DB}}
if [ -z "${DB_NAME}"]
then
    DB_NAME=$(echo $SQL | grep -oE '(Database: (\w*))' | cut -d ' ' -f 2)
fi
[ -z "${DB_NAME}" ] && { echo "=> database name cannot be found" && exit 1; }

echo "=> Restore database $DB_NAME from $1"

if echo $SQL | mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$DB_NAME"
then
    echo "=> Restore succeeded"
else
    echo "=> Restore failed"
fi
