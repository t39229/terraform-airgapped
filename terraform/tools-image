FROM alpine:3.15.4

RUN apk update
RUN apk add vim
RUN apk add curl
RUN apk add ca-certificates
RUN update-ca-certificates
RUN apk add openssl
RUN apk add tcpdump
RUN apk add tshark

# Install redis (for redis-cli)
RUN apk add redis

# Install psql
RUN apk add postgresql-client

# Busybox tools collection
RUN apk add busybox-extras
