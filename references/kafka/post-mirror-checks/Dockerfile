FROM --platform=linux/amd64 python:3.11

WORKDIR /opt/kafka-checker

RUN apt update && \
	apt-get install -y librdkafka-dev && \
	curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc

RUN mkdir reports

COPY requirements.txt /opt/kafka-checker
RUN pip3 install -r requirements.txt --break-system-packages

COPY main_compare.py main_save.py before_switch.sh after_switch.sh /opt/kafka-checker

# RUN addgroup -g 1001 etl && \
# 	adduser -H -D -u 1001 -G etl etl

# CMD ["tail", "-f", "/dev/null"]