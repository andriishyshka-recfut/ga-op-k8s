import json
import kafka
brokers = ['broker-0.p.regemini.io:32200', 'broker-0.p.regemini.io:32200', 'broker-0.p.regemini.io:32200']
admin_client = kafka.KafkaAdminClient(bootstrap_servers=brokers)
topics = ["dome", 'minion', 'crypto', 'maid', 'whirl', 'mage']
work_topics = {}
print_topic = []
for topic in admin_client.list_topics():
    if topic.split('.')[0] in topics:
        work_topics[topic.replace('_','.')] = topic
        print_topic.append(topic)
print(json.dumps(work_topics))

# print_topic.sort()
# for test_print in print_topic:
#     print(f"\"{test_print}\",")
