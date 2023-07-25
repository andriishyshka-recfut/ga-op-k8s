from confluent_kafka.admin import AdminClient, ConfigResource
import socket

conf ={"bootstrap.servers":"broker-0.p.regemini.io:32200,broker-0.p.regemini.io:32201"}
admin_client = AdminClient(conf)
topic_list = []
topic_list.append(ConfigResource(restype='TOPIC', name='dome.0x00sec.post', set_config={"retention.ms":"604800000"}, described_configs=None, error=None))
admin_client.alter_configs(resources=topic_list, validate_only=False)