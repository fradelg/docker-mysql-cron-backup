#!/bin/bash

db=$1
EXT=$2

# This file could be customized to create custom delete strategy

while [ "$(find /backup -maxdepth 1 -name "*.$db.sql$EXT" -type f | wc -l)" -gt "$MAX_BACKUPS" ]
do
  TARGET=$(find /backup -maxdepth 1 -name "*.$db.sql$EXT" -type f | sort | head -n 1)
  echo "==> Max number of ($MAX_BACKUPS) backups reached. Deleting ${TARGET} ..."
  rm -rf "${TARGET}"
  echo "==> Backup ${TARGET} deleted"
done