# mysql-cron-backup

This image runs mysqldump to backup database periodically using cron. Data is dumped to the container folder `/backup`

## Usage:

  docker run -d \
    --env MYSQL_USER=admin \
    --env MYSQL_PASS=password \
    --link mysql
    --volume /path/to/my/host/folder:/backup
    fradelg/mysql-backup

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

See the list of backups, you can run:

    docker exec backup ls /backup

To restore database from a certain backup, simply run:

    docker exec backup /restore.sh /backup/2015.08.06.171901
