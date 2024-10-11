#!/bin/bash

python main_save.py -s kafka-cluster-kafka-0.kafka-cluster-kafka-brokers:9092  -p reports/prod_dr && \
mc cp -r reports backup/${MC_BUCKET}/
