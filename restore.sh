#!/bin/bash
echo "=> Restore database from \$1"
if mysql -h $MYSQL_HOST -P $MYSQL_POR -u $MYSQL_USER -p$MYSQL_PASS < \$1 ;then
    echo "=> Restore succeeded"
else
    echo "=> Restore failed"
fi
