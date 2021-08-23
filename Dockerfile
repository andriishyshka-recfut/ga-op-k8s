FROM vault:latest as vault
FROM hashicorp/terraform:1.0.4 as terraform
FROM curlimages/curl as curl
RUN curl https://storage.googleapis.com/kubernetes-release/release/$(wget -q -O- https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl --output /tmp/kubectl &&\
    curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.31.4/terragrunt_linux_amd64 --output /tmp/terragrunt


FROM alpine:latest as ansible
RUN apk add python3 py3-pip unzip py3-virtualenv bash python3-dev libffi-dev build-base rust rustup cargo openssl-dev musl-dev
RUN cd / && python3 -m venv ansible && \
    bash -c "source /ansible/bin/activate && pip install --upgrade pip && pip install ansible pyyaml docker-compose jmespath kubernetes openshift requests google-auth ansible-modules-hashivault pyopenssl"


FROM alpine:latest


COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=vault /bin/vault /bin/vault
COPY --from=curl /tmp/kubectl /bin/kubectl
COPY --from=curl /tmp/terragrunt /bin/terragrunt
COPY --from=ansible /ansible /ansible

RUN apk add  --no-cache tar openssh-client jq bash rsync python3 openssl git && \
    chmod +x /bin/kubectl && chmod +x /bin/terragrunt && \
    adduser -u 10123 executor -S && \
    mkdir -p /home/runner/workdir && mkdir /home/fake && chmod 777 /home/fake

USER 10123
WORKDIR /home/runner/workdir

COPY ./docker-entrypoint.sh /
COPY ./docker-entrypoint-tg.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
