[![Build Status](https://travis-ci.org/fradelg/docker-mysql-cron-backup.svg?branch=master)](https://travis-ci.org/fradelg/docker-mysql-cron-backup)

# mysql-cron-backup

This docker image runs mysqldump to backup your databases periodically using cron task manager. Backups are placed in `/backup` so you can mount your backup docker volume in this path.

## Usage:

```bash
docker container run -d \
       --env MYSQL_USER=root \
       --env MYSQL_PASS=my_password \
       --link mysql
       --volume /path/to/my/backup/folder:/backup
       fradelg/mysql-cron-backup
```

## Variables

- `MYSQL_HOST`: The host/ip of your mysql database.
- `MYSQL_PORT`: The port number of your mysql database.
- `MYSQL_USER`: The username of your mysql database.
- `MYSQL_PASS`: The password of your mysql database.
- `MYSQL_DB`: The database name to dump. Default: `--all-databases`.
- `MYSQLDUMP_OPTS`: Command line arguments to pass to mysqldump. Example: `--single-transaction`.
- `CRON_TIME`: The interval of cron job to run mysqldump. `0 3 * * sun` by default, which is every Sunday at 03:00.
- `MAX_BACKUPS`: The number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default.
- `INIT_BACKUP`: If set, create a backup when the container starts.
- `INIT_RESTORE_LATEST`: If set, restores latest backup.
- `TIMEOUT`: Wait a given number of seconds for the database to be ready and make the first backup, `10s` by default. After that time, the initial attempt for backup gives up and only the Cron job will try to make a backup.
- `GZIP_LEVEL`: Specify the level of gzip compression from 1 (quickest, least compressed) to 9 (slowest, most compressed), default is 6.

If you want to make this image the perfect companion of your MySQL container, use [docker-compose](https://docs.docker.com/compose/). You can add more services that will be able to connect to the MySQL image using the name `my_mariadb`, note that you only expose the port `3306` internally to the servers and not to the host:

```yaml
version: "2"
services:
  mariadb:
    image: mariadb
    container_name: my_mariadb
    expose:
      - 3306
    volumes:
      - data:/var/lib/mysql
      # If there is not scheme, restore the last created backup (if exists)
      - ${VOLUME_PATH}/backup/latest.${DATABASE_NAME}.sql.gz:/docker-entrypoint-initdb.d/database.sql.gz
    environment:
      - MYSQL_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DATABASE_NAME}
    restart: unless-stopped

  mysql-cron-backup:
    image: fradelg/mysql-cron-backup
    depends_on:
      - mariadb
    volumes:
      - ${VOLUME_PATH}/backup:/backup
    environment:
      - MYSQL_HOST=my_mariadb
      - MYSQL_USER=root
      - MYSQL_PASS=${MARIADB_ROOT_PASSWORD}
      - MAX_BACKUPS=15
      - INIT_BACKUP=0
      # Every day at 03:00
      - CRON_TIME=0 3 * * *
      # Make it small
      - GZIP_LEVEL=9
    restart: unless-stopped

volumes:
  data:
```

## Restore from a backup

See the list of backups in your running docker container, just write in your favorite terminal:

```bash
docker container exec backup ls /backup
```

To restore a database from a certain backup, simply run:

```bash
docker container exec backup /restore.sh /backup/201708060500.my_db.sql.gz
```
