FROM alpine
MAINTAINER Fco. Javier Delgado del Hoyo <frandelhoyo@gmail.com>

RUN apk add --update bash mysql-client gzip && rm -rf /var/cache/apk/* && mkdir /backup

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306"

COPY run.sh /run.sh
COPY backup.sh /backup.sh
COPY restore.sh /restore.sh
RUN chmod +x /backup.sh /restore.sh

VOLUME ["/backup"]

CMD ["/run.sh"]
