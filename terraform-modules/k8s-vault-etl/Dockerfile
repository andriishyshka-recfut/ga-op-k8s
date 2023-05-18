FROM --platform=linux/amd64 docker.io/alpine

RUN apk add --no-cache \
	ca-certificates \
	openssh \
	make \
	just \
	py3-dnspython \
	py3-passlib \
    py3-pip

RUN pip3 install kopf && \
    pip3 install kubernetes

ENV OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

WORKDIR /opt/etl

COPY etl-operator.py job_template.yaml /opt/etl

CMD ["kopf", "run", "etl-operator.py"]