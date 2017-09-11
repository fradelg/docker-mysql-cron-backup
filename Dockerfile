FROM alpine:3.5
LABEL maintainer "Fco. Javier Delgado del Hoyo <frandelhoyo@gmail.com>"

RUN apk add --update bash mysql-client gzip && rm -rf /var/cache/apk/* && mkdir /backup

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306"

COPY ["run.sh", "backup.sh", "restore.sh", "/"]
RUN chmod u+x /backup.sh /restore.sh

VOLUME ["/backup"]

CMD ["/run.sh"]
