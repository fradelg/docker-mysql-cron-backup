[![Build Status](https://travis-ci.org/fradelg/docker-mysql-cron-backup.svg?branch=master)](https://travis-ci.org/fradelg/docker-mysql-cron-backup)

# mysql-cron-backup

This docker image runs mysqldump to backup your databases periodically using cron task manager. Backups are placed in `/backup` so you can mount your backup docker volume in this path.

## Usage:

  docker container run -d \
    --env MYSQL_USER=root \
    --env MYSQL_PASS=my_password \
    --link mysql
    --volume /path/to/my/backup/folder:/backup
    fradelg/mysql-cron-backup

## Variables

    MYSQL_HOST      the host/ip of your mysql database
    MYSQL_PORT      the port number of your mysql database
    MYSQL_USER      the username of your mysql database
    MYSQL_PASS      the password of your mysql database
    MYSQL_DB        the database name to dump. Default: `--all-databases`
    CRON_TIME       the interval of cron job to run mysqldump. `0 0 * * *` by default, which is every day at 00:00
    MAX_BACKUPS     the number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default
    INIT_BACKUP     if set, create a backup when the container starts
    INIT_RESTORE_LATEST if set, restores latest backup

## Restore from a backup

See the list of backups in your running docker container, just write in your favorite terminal:

    docker container exec backup ls /backup

To restore a database from a certain backup, simply run:

    docker container exec backup /restore.sh /backup/201708060500.my_db.sql.gz
