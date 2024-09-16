FROM --platform=linux/amd64 python:3.11

WORKDIR /opt/kafka-checker

RUN apt update && \
	apt-get install -y librdkafka-dev && \
	curl https://dl.min.io/client/mc/release/linux-amd64/mc ./mc && \
    chmod +x ./mc


RUN mkdir reports

COPY requirements.txt main_compare.py main_save.py run_on_old.sh run_on_new.sh /opt/kafka-checker

RUN pip3 install -r requirements.txt --break-system-packages

# RUN addgroup -g 1001 etl && \
# 	adduser -H -D -u 1001 -G etl etl
#
# ENV OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES


CMD ["tail", "-f", "/dev/null"]