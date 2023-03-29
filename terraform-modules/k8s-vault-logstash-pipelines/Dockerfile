FROM --platform=linux/amd64 docker.elastic.co/logstash/logstash:7.17.9

RUN /usr/share/logstash/bin/logstash-plugin install logstash-codec-csv

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]