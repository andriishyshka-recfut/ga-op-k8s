import getopt
import json
import sys
import timeit
from concurrent.futures import ThreadPoolExecutor
from tabulate import tabulate

from confluent_kafka import Consumer, TopicPartition, OFFSET_INVALID
from confluent_kafka.admin import (AdminClient)
from deepdiff import DeepDiff

from kafka import KafkaAdminClient

UNKNOWN_GROUP = "<not associated>"

EXCLUDED_TOPICS = ["__consumer_offsets", "mirrormaker2-cluster-offsets", "mirrormaker2-cluster-status",
                   "mirrormaker2-cluster-configs", "mm2-offset-syncs.target.internal"]


def print_state_comparison(src, tgt):
    print("\n\nData changes:")
    header = ['Topic', 'Group', 'Partition', 'Low', 'High', 'Size', 'Lag']
    changed_items = [header]
    suspicious_items = [header]
    global show_all

    offset_fix = []
    src_only_topics = set(src.keys()).difference(set(tgt.keys()))
    tgt_only_topics = set(tgt.keys()).difference(set(src.keys()))
    skip_topics = set()

    if len(src_only_topics) > 0:
        print("Topics only in Source:", src_only_topics)
        skip_topics.update(src_only_topics)
    if len(tgt_only_topics) > 0:
        print("Topics only in Target:", tgt_only_topics)
        skip_topics.update(tgt_only_topics)

    epl_file = open("epl_diff.txt", "w")
    for rec in src.items():
        topic, topic_data = rec

        if topic not in skip_topics:
            for grp_rec in topic_data.items():
                group, partitions = grp_rec

                for p_rec in partitions.items():
                    part_id, src_values = p_rec

                    try:
                        tgt_values = tgt.get(topic).get(group).get(part_id)

                        lag, high, low, size = "", "", "", ""
                        new_offset = 0
                        has_changed = False
                        lag_or_size_mismatch = False
                        if src_values.get("low") != tgt_values.get("low"):
                            has_changed = True
                            low = "{} -> {}".format(src_values.get("low"), tgt_values.get("low"))
                        if src_values.get("high") != tgt_values.get("high"):
                            has_changed = True
                            high = "{} -> {}".format(src_values.get("high"), tgt_values.get("high"))
                        if src_values.get("lag") != tgt_values.get("lag"):
                            has_changed = True
                            lag_or_size_mismatch = True
                            lag = "{} -> {}".format(src_values.get("lag"), tgt_values.get("lag"))
                            new_offset = int(tgt_values.get("high")) - int(src_values.get("lag"))
                            if new_offset < 0:
                                new_offset = 0
                        if src_values.get("size") != tgt_values.get("size"):
                            has_changed = True
                            lag_or_size_mismatch = True
                            size = "{} -> {}".format(src_values.get("size"), tgt_values.get("size"))

                        if lag_or_size_mismatch:
                            suspicious_items.append([topic, group, part_id, low, high, size, lag])
                            epl_file.write("Topic: {} Group: {} Partition: {} L-Offset: {} H-Offset: {} "
                                           "Size: {} Lag: {}\n".format(topic, group, part_id, low, high, size, lag))

                        if has_changed:
                            changed_items.append([topic, group, part_id, low, high, size, lag])
                            # epl_file.write("Topic: {} Group: {} Partition: {} L-Offset: {} H-Offset: {} "
                            #                "Size: {} Lag: {}\n".format(topic, group, part_id, low, high, size, lag))

                            if new_offset != 0:
                                offset_fix.append(
                                    "./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --reset-offsets "
                                    "--group {} --topic {}:{} --to-offset {} --execute".format(
                                        group, topic, part_id, new_offset))


                    except Exception as e:
                        print("failed to compare data for", topic, e)

    epl_file.close()

    if show_all:
        print("All changes in topics:")
        print(tabulate(changed_items, headers='firstrow', tablefmt='fancy_grid'))
    else:
        print("Topics with lag/size inconsistency:")
        print(tabulate(suspicious_items, headers='firstrow', tablefmt='fancy_grid'))


    print("\n\nProposed offset fixes:")
    print("\n".join(str(x) for x in offset_fix))
    print("\n\n")


def get_partition_size(topic_name: str, partition_key: int, consumer):
    partition_data = dict()
    partition_data[partition_key] = dict()
    topic_partition = TopicPartition(topic_name, partition_key)
    low_offset, high_offset = consumer.get_watermark_offsets(topic_partition)
    committed = consumer.committed([topic_partition], timeout=10)
    partition_size = high_offset - low_offset

    partition_data.get(partition_key)["low"] = low_offset
    partition_data.get(partition_key)["high"] = high_offset
    partition_data.get(partition_key)["size"] = partition_size

    if committed[0].offset != OFFSET_INVALID:
        lag = "%d" % (high_offset - committed[0].offset)
        partition_data.get(partition_key)["lag"] = lag

    return partition_data


def get_topic_size(topic, bootstrap_server):
    topic_name = topic[0]
    topic_data = dict()
    topic_data[topic_name] = dict()

    for group_data in topic[1].items():
        group_name = group_data[0]
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
    filename = cluster_name + '.json'
    print("\t\tSaving data to", filename)
    json_file = open(filename, "w")
    json_file.write(json.dumps(cluster_state, sort_keys=True, indent=4))
    json_file.close()

    print('\tTime:', int(stop - start), "seconds")
    return cluster_state


def parse_args(argv):
    source_broker, target_broker = '', ''
    global show_all

    try:
        opts, args = getopt.getopt(argv, "ahs:t:", ["src=", "target="])
    except getopt.GetoptError:
        print('main.py -s <source broker host:port> -t <target broker host:port> [-a]')
        print('\t-a - show all changes (by default only topics with lag/size mismatch are shown)')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('main.py -s <source broker host:port> -t <target broker host:port>')
            sys.exit()
        elif opt in ("-s", "--src"):
            source_broker = arg
        elif opt in ("-t", "--target"):
            target_broker = arg
        elif opt in ("-a", "--all"):
            show_all = True

    return source_broker, target_broker


#########################################
#   Main body
#########################################

source_broker, target_broker = parse_args(sys.argv[1:])
show_all = False

source_server_state = analyze_cluster("source", source_broker)
target_server_state = analyze_cluster("target", target_broker)

diff = DeepDiff(source_server_state, target_server_state, ignore_order=True)

filename = "differences.json"

print_state_comparison(source_server_state, target_server_state)

# print("Saving differences analysis to", filename)
# json_file = open(filename, "w")
# json_file.write(json.dumps(diff.to_dict(), sort_keys=True, indent=4))
# json_file.close()

print("All done")
