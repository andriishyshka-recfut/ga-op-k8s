#!/bin/bash

mc cp -r backup/${MC_BUCKET}/reports/prod_dr_$(date +%y-%m-%d) reports && \
python main_compare.py -t kafka-cluster-kafka-0.kafka-cluster-kafka-brokers:9092 -p reports/prod_dr > reports/prod_dr_$(date +%y-%m-%d)/run_log.txt && \
mc cp -r reports backup/${MC_BUCKET}/
