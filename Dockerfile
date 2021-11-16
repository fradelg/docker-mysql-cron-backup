FROM golang:1.15.8-alpine3.12 AS binary
RUN apk -U add openssl git

ARG DOCKERIZE_VERSION=v0.6.1
WORKDIR /go/src/github.com/jwilder
RUN git clone https://github.com/jwilder/dockerize.git && \
    cd dockerize && \
    git checkout ${DOCKERIZE_VERSION}

WORKDIR /go/src/github.com/jwilder/dockerize
RUN go get github.com/robfig/glock
RUN glock sync -n < GLOCKFILE
RUN go install

FROM alpine:3.14.3
LABEL maintainer "Fco. Javier Delgado del Hoyo <frandelhoyo@gmail.com>"

RUN apk add --update \
        tzdata \
        bash \
        mysql-client \
        gzip \
        openssl \
        mariadb-connector-c && \
    rm -rf /var/cache/apk/*

COPY --from=binary /go/bin/dockerize /usr/local/bin

ENV CRON_TIME="0 3 * * sun" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306" \
    TIMEOUT="10s"

COPY ["run.sh", "backup.sh", "restore.sh", "/"]
RUN mkdir /backup && \
    chmod 777 /backup && \ 
    chmod 755 /run.sh /backup.sh /restore.sh && \
    touch /mysql_backup.log && \
    chmod 666 /mysql_backup.log

VOLUME ["/backup"]

CMD dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout ${TIMEOUT} /run.sh
