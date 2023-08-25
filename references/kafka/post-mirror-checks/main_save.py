import os
import datetime
import getopt
import json
import sys
import timeit
from concurrent.futures import ThreadPoolExecutor
from confluent_kafka.cimpl import RESOURCE_TOPIC
from tabulate import tabulate

from confluent_kafka import Consumer, TopicPartition, OFFSET_INVALID
from confluent_kafka.admin import (AdminClient, ConfigResource)
from deepdiff import DeepDiff

from kafka import KafkaAdminClient

FIELD_RETENTION_MS = 'retention_ms'
FIELD_LOW = 'low'
FIELD_HIGH = 'high'
FIELD_LAG = 'lag'
FIELD_SIZE = 'size'

UNKNOWN_GROUP = "<not associated>"
SPECIAL_FIELDS = [FIELD_RETENTION_MS]

EXCLUDED_TOPICS = ["__consumer_offsets", "mirrormaker2-cluster-offsets", "mirrormaker2-cluster-status",
                   "mirrormaker2-cluster-configs", "mm2-offset-syncstargetinternal", "mm2-offset-syncs.target.internal",
                   "__strimzi_store_topic", "__strimzi-topic-operator-kstreams-topic-store-changelog", "sourcecheckpointsinternal" ]

now = datetime.datetime.now().strftime('%y-%m-%d')
results_folder = ""


def get_partition_size(topic_name: str, partition_key: int, consumer):
    partition_data = dict()
    partition_data[partition_key] = dict()
    topic_partition = TopicPartition(topic_name, partition_key)
    low_offset, high_offset = consumer.get_watermark_offsets(topic_partition)
    committed = consumer.committed([topic_partition], timeout=10)
    partition_size = high_offset - low_offset

    partition_data.get(partition_key)[FIELD_LOW] = low_offset
    partition_data.get(partition_key)[FIELD_HIGH] = high_offset
    partition_data.get(partition_key)[FIELD_SIZE] = partition_size

    if committed[0].offset != OFFSET_INVALID:
        lag = high_offset - committed[0].offset
        partition_data.get(partition_key)[FIELD_LAG] = lag

    return partition_data


def get_topic_size(topic, bootstrap_server):
    topic_name = topic[0]
    topic_data = dict()
    topic_data[topic_name] = dict()

    for group_data in topic[1].items():
        group_name = group_data[0]
        if group_name in SPECIAL_FIELDS:
            continue
        partitions = group_data[1]
        topic_data.get(topic_name)[group_name] = dict()
        workers, max_workers = [], len(partitions) or 1

        consumer = Consumer({"bootstrap.servers": bootstrap_server, "group.id": group_name})

        with ThreadPoolExecutor(max_workers=max_workers) as e:
            for partition_key in partitions.keys():
                job = e.submit(get_partition_size, topic_name, partition_key, consumer)
                workers.append(job)

        for w in workers:
            topic_data.get(topic_name)[group_name].update(w.result())

        consumer.close()
    return topic_data


def get_topic_group_map(topics, groups, bootstrap_server):
    all_topics_data = dict()
    admin_client2 = KafkaAdminClient(bootstrap_servers=[bootstrap_server])

    workers = dict()

    with ThreadPoolExecutor(max_workers=10) as e:
        for group in groups:
            job = e.submit(admin_client2.list_consumer_group_offsets, group.id)
            workers[group.id] = job

        for items in workers.items():
            group, w = items
            for rec in w.result():
                name = rec.topic
                if name not in EXCLUDED_TOPICS:
                    if name not in all_topics_data.keys():
                        all_topics_data[name] = dict()
                    all_topics_data.get(name)[group] = dict()

    admin_client2.close()

    for topic in topics.items():
        topic_name = topic[0]
        if topic_name not in EXCLUDED_TOPICS:
            if topic_name not in all_topics_data.keys():
                all_topics_data[topic_name] = dict()
                all_topics_data.get(topic_name)[UNKNOWN_GROUP] = topic[1].partitions

            else:
                for group in all_topics_data.get(topic_name):
                    all_topics_data.get(topic_name)[group] = topic[1].partitions

    return all_topics_data


def analyze_cluster(cluster_name, bootstrap_server):
    print("Analyzing", cluster_name, "cluster")
    start = timeit.default_timer()
    a = AdminClient({'bootstrap.servers': bootstrap_server})

    topics = a.list_topics(timeout=90).topics
    groups = a.list_groups(timeout=90)

    print("\tTotal topics: {} (with {} topic(s) excluded from analysis)".format(len(topics), len(EXCLUDED_TOPICS)))
    print("\tTotal groups:", len(groups))

    print("\t\tGenerating topic-group association maps")
    all_topics_data = get_topic_group_map(topics, groups, bootstrap_server)

    cluster_state = dict()

    print("\t\tFetching topics retention policy")

    topics_config_resource = []
    for topic in all_topics_data.items():
        topic_name = topic[0]
        topics_config_resource.append(ConfigResource(name=topic_name, restype=RESOURCE_TOPIC))
    topics_config = a.describe_configs(topics_config_resource)

    for t_config in topics_config.items():
        all_topics_data.get(t_config[0].name)[FIELD_RETENTION_MS] = t_config[1].result()['retention.ms'].value

    workers = []
    print("\t\tFetching lag, offsets and size of topics")
    with ThreadPoolExecutor(max_workers=20) as e:
        for topic in all_topics_data.items():
            job = e.submit(get_topic_size, topic, bootstrap_server)
            workers.append(job)

    for w in workers:
        cluster_state.update(w.result())

    stop = timeit.default_timer()

    # print(json.dumps(cluster_status, sort_keys=True, indent=4))
    filename = "{}/{}.json".format(results_folder , cluster_name,)
    print("\t\tSaving data to", filename)
    json_file = open(filename, "w")
    json_file.write(json.dumps(cluster_state, sort_keys=True, indent=4))
    json_file.close()

    print('\tTime:', int(stop - start), "seconds")
    return cluster_state


def parse_args(argv):
    source_broker, target_broker, run_prefix = '', '', 'logs'
    global show_all

    try:
        opts, args = getopt.getopt(argv, "ahs:t:p:", ["src=", "target=", "prefix="])
    except getopt.GetoptError:
        print('main.py -s <source broker host:port> [-a]')
        print('\t-a - show all changes (by default only topics with lag/size mismatch are shown)')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('main.py -s <source broker host:port>  [-a]')
            sys.exit()
        elif opt in ("-s", "--src"):
            source_broker = arg
        elif opt in ("-p", "--prefix"):
            run_prefix = arg
        elif opt in ("-a", "--all"):
            show_all = True

    return source_broker, run_prefix


#########################################
#   Main body
#########################################

source_broker, run_prefix = parse_args(sys.argv[1:])
show_all = False

results_folder = f'{run_prefix}_{now}'
os.mkdir(results_folder)
source_server_state = analyze_cluster("source", source_broker)

print("All done")
