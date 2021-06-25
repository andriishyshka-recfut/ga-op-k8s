FROM vault:latest as vault
FROM hashicorp/terraform:1.0.1 as terraform
FROM curlimages/curl as curl
RUN curl https://storage.googleapis.com/kubernetes-release/release/$(wget -q -O- https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl --output /tmp/kubectl


FROM debian:10 as ansible
RUN apt update && \
    apt install -y python3 python3-pip unzip ssh jq wget curl rustc libssl-dev python3-venv
RUN cd / && python3 -m venv ansible && \
    bash -c "source /ansible/bin/activate &&  pip install ansible jmespath kubernetes openshift requests google-auth ansible-modules-hashivault pyopenssl" &&\
    rm -rf /var/lib/apt/lists/*


FROM alpine:latest


RUN apk add   openssh-client jq bash  python3  && \
    mkdir -p /home/runner/workdir && mkdir /home/fake && chmod 777 /home/fake

COPY --from=terraform /bin/terraform /bin/terraform
COPY --from=vault /bin/vault /bin/vault
COPY --from=curl /tmp/kubectl /bin/kubectl
COPY --from=ansible /ansible /ansible

#RUN apt update && \
#    apt install -y python3 python3-pip unzip ssh jq wget curl rustc libssl-dev && \
#    python3 -m pip install ansible==2.10.5 jmespath kubernetes openshift requests google-auth ansible-modules-hashivault pyopenssl &&\
#    rm -rf /var/lib/apt/lists/*

#RUN wget  -q https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip -O /usr/bin/terraform.zip && \
#    unzip /usr/bin/terraform.zip -d /usr/bin && \
#    wget -q https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl -O /usr/bin/kubectl && \
#    chmod +x /usr/bin/terraform /usr/bin/kubectl &&\
#    wget -q https://releases.hashicorp.com/vault/1.6.2/vault_1.6.2_linux_amd64.zip -O /usr/bin/vault_1.6.2_linux_amd64.zip &&\
#    unzip /usr/bin/vault_1.6.2_linux_amd64.zip -d /usr/bin

#RUN mkdir -p /home/runner/workdir &&\
#    chmod 777 /usr/local/lib/python3.7/dist-packages/certifi/cacert.pem &&\
#    mkdir /home/fake && chmod 777 /home/fake

USER 10123
WORKDIR /home/runner/workdir

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
