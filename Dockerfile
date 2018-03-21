FROM alpine:3.7
LABEL maintainer "Fco. Javier Delgado del Hoyo <frandelhoyo@gmail.com>"

COPY ["run.sh", "backup.sh", "restore.sh", "/"]

RUN apk add --update bash mysql-client gzip && rm -rf /var/cache/apk/* && mkdir /backup &&\
  chmod u+x /backup.sh /restore.sh

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306"

VOLUME ["/backup"]

CMD ["/run.sh"]
