FROM vault:1.20.0 as vault
FROM hashicorp/terraform:1.12.2 as terraform
FROM curlimages/curl as curl
RUN curl https://storage.googleapis.com/kubernetes-release/release/$(wget -q -O- https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl --output /tmp/kubectl &&\
    curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v0.83.1/terragrunt_linux_amd64 --output /tmp/terragrunt

FROM alpine:latest as ansible
RUN apk add python3 py3-pip unzip py3-virtualenv bash python3-dev libffi-dev build-base rust rustup cargo openssl-dev musl-dev
RUN cd / && python3 -m venv ansible && \
    bash -c "source /ansible/bin/activate && pip install --upgrade pip && pip install ansible pyyaml==5.3.1 docker-compose jmespath kubernetes openshift requests google-auth ansible-modules-hashivault pyopenssl kafka-python"


FROM --platform=linux/amd64 openjdk:18-jdk-alpine as java

FROM alpine:latest


COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=vault /bin/vault /bin/vault
COPY --from=curl /tmp/kubectl /bin/kubectl
COPY --from=curl /tmp/terragrunt /bin/terragrunt
COPY --from=ansible /ansible /ansible
COPY --from=java /opt/openjdk-18 /opt/openjdk-18
COPY --from=java /etc/ssl/certs/java/cacerts /etc/ssl/certs/java/cacerts

ENV JAVA_HOME=/opt/openjdk-18


RUN apk add  --no-cache tar openssh-client jq bash rsync python3 openssl git curl && \
    chmod +x /bin/kubectl && chmod +x /bin/terragrunt && \
    adduser -u 10123 executor -S && \
    mkdir -p /home/runner/workdir && mkdir /home/fake && chmod 777 /home/fake

USER 10123
RUN mkdir /home/fake/.terraform.d/plugins/registry.terraform.io/aminueza/minio/3.6.5/linux_amd64/
COPY ./references/minio-provider/terraform-provider-minio /home/fake/.terraform.d/plugins/registry.terraform.io/aminueza/minio/3.6.5/linux_amd64/
WORKDIR /home/runner/workdir
COPY ./dummy-kubecfg /.kubeconfig
COPY ./docker-entrypoint.sh /
COPY ./docker-entrypoint-tg.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
