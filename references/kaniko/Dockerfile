FROM gcr.io/kaniko-project/executor:debug AS kaniko
FROM alpine:3.16.0

RUN apk --update add jq vault libcap
RUN setcap cap_ipc_lock= /usr/sbin/vault

COPY --from=kaniko /kaniko/ /kaniko/

ENV PATH $PATH:/usr/local/bin:/kaniko
ENV DOCKER_CONFIG /kaniko/.docker/
ENV SSL_CERT_DIR /kaniko/ssl/certs