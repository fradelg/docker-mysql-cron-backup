FROM alpine:3.7
LABEL maintainer "Fco. Javier Delgado del Hoyo <frandelhoyo@gmail.com>"

COPY ["run.sh", "backup.sh", "restore.sh", "/"]

RUN apk add --update bash mysql-client gzip openssl && rm -rf /var/cache/apk/* && mkdir /backup &&\
  chmod u+x /backup.sh /restore.sh

ENV DOCKERIZE_VERSION v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306" \
    TIMEOUT="10s"

VOLUME ["/backup"]

CMD dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout ${TIMEOUT} /run.sh
