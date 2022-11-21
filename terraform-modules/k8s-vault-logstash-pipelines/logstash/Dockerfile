FROM docker.elastic.co/logstash/logstash:8.4.3

RUN /usr/share/logstash/bin/logstash-plugin install logstash-codec-csv

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]