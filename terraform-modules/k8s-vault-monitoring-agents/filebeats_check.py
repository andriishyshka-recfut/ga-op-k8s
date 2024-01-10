from kubernetes import client, config
import json,time,os

# Configs can be set in Configuration class directly or using helper utility
config.load_incluster_config()

api = client.AppsV1Api()
name = os.getenv('DAEMONSET_NAME')
namespace = os.getenv('NAMESPACE')
pretty = 'true'

def api_response():
  return api.read_namespaced_daemon_set_status(name, namespace, pretty=pretty)

def desired_pods():
  return api_response().status.desired_number_scheduled
def ready_pods():
  return api_response().status.number_ready

for iterator in range(10):
  if desired_pods() > ready_pods():
    print(iterator, "th iteration")
    time.sleep(60)
    continue
  else:
    break

print("Here is STATUS:", "\n\n", api_response().status)

if desired_pods() == ready_pods():
  print("\n", "Filebeat pods are ready")
else:
  print("\n", "Failed, ready pods not quel to desired")
  exit(1)