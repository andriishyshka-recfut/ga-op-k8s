FROM debian:10


RUN apt update && \
    apt install -y python3 python3-pip unzip ssh jq wget && \
    python3 -m pip install ansible==2.9.9 kubernetes openshift requests google-auth

RUN wget  https://releases.hashicorp.com/terraform/0.12.25/terraform_0.12.25_linux_amd64.zip -O /usr/bin/terraform_0.12.25_linux_amd64.zip && \
    unzip /usr/bin/terraform_0.12.25_linux_amd64.zip -d /usr/bin && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl -O /usr/bin/kubectl && \
    chmod +x /usr/bin/terraform /usr/bin/kubectl  && \
    mkdir -p /home/runner/workdir

USER 10123
WORKDIR /home/runner/workdir

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["plan"]
