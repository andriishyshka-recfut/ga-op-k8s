FROM debian:10


RUN apt update && \
    apt install -y python3 python3-pip unzip ssh jq wget curl && \
    python3 -m pip install ansible==2.10.4 kubernetes openshift requests google-auth ansible-modules-hashivault pyopenssl &&\
    rm -rf /var/lib/apt/lists/*

RUN wget  https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_linux_amd64.zip -O /usr/bin/terraform_0.13.4_linux_amd64.zip && \
    unzip /usr/bin/terraform_0.13.4_linux_amd64.zip -d /usr/bin && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl -O /usr/bin/kubectl && \
    chmod +x /usr/bin/terraform /usr/bin/kubectl &&\
    wget https://releases.hashicorp.com/vault/1.4.2/vault_1.4.2_linux_amd64.zip -O /usr/bin/vault_1.4.2_linux_amd64.zip &&\
    unzip /usr/bin/vault_1.4.2_linux_amd64.zip -d /usr/bin

RUN mkdir -p /home/runner/workdir &&\
    chmod 777 /usr/local/lib/python3.7/dist-packages/certifi/cacert.pem &&\
    mkdir /home/fake && chmod 777 /home/fake

USER 10123
WORKDIR /home/runner/workdir

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["plan"]
