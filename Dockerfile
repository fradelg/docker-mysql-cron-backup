FROM golang:1.20.4-alpine3.18 AS binary
RUN apk -U add openssl git

ARG DOCKERIZE_VERSION=v0.7.0
WORKDIR /go/src/github.com/jwilder
RUN git clone https://github.com/jwilder/dockerize.git && \
    cd dockerize && \
    git checkout ${DOCKERIZE_VERSION}

WORKDIR /go/src/github.com/jwilder/dockerize
ENV GO111MODULE=on
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GO111MODULE=on go build -a -o /go/bin/dockerize .

FROM alpine:3.18.3
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
    TIMEOUT="10s" \
    MYSQLDUMP_OPTS="--quick"

COPY ["run.sh", "backup.sh", "restore.sh", "/delete.sh", "/"]
RUN mkdir /backup && \
    chmod 777 /backup && \ 
    chmod 755 /run.sh /backup.sh /restore.sh /delete.sh && \
    touch /mysql_backup.log && \
    chmod 666 /mysql_backup.log

VOLUME ["/backup"]

HEALTHCHECK --interval=2s --retries=1800 \
	CMD stat /HEALTHY.status || exit 1

ENTRYPOINT dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout ${TIMEOUT} 
CMD [ "/run.sh" ]