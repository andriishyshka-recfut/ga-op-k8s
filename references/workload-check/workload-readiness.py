from kubernetes import client, config
import json,time,re

# Configs can be set in Configuration class directly or using helper utility
config.load_incluster_config()

api = client.AppsV1Api()

def desired_pods(**kwargs):
    workload_type = kwargs['workload_type']
    if workload_type == "daemonset":
        try:
            return api.read_namespaced_daemon_set_status(kwargs['workload_name'], kwargs['workload_namespace'], pretty='true').status.desired_number_scheduled
        except Exception as e:
            print(json.loads(e.body)['message'])
            exit()

    elif workload_type == "deployment":
        try:
            return api.read_namespaced_deployment_status(kwargs['workload_name'], kwargs['workload_namespace'], pretty='true').status.replicas
        except Exception as e:
            print(json.loads(e.body)['message'])
            exit()

    elif workload_type == "statefulset":
        try:
            return api.read_namespaced_stateful_set_status(kwargs['workload_name'], kwargs['workload_namespace'], pretty='true').status.replicas
        except Exception as e:
            print(json.loads(e.body)['message'])
            exit()

    else:
        try:
            api.list_namespaced_some_workload
        except Exception as e:
            print("Incorrect workload type. Please specify either deployment, statefulset, daemonset\n")
            exit()


def ready_pods(**kwargs):
    workload_type = kwargs['workload_type']
    if workload_type == "daemonset":
        try:
            return api.read_namespaced_daemon_set_status(kwargs['workload_name'], kwargs['workload_namespace'], pretty='true').status.number_ready
        except Exception as e:
            print(json.loads(e.body)['message'])
            exit()

    elif workload_type == "deployment":
        try:
            return api.read_namespaced_deployment_status(kwargs['workload_name'], kwargs['workload_namespace'], pretty='true').status.ready_replicas
        except Exception as e:
            print(json.loads(e.body)['message'])
            exit()

    elif workload_type == "statefulset":
        try:
            return api.read_namespaced_stateful_set_status(kwargs['workload_name'], kwargs['workload_namespace'], pretty='true').status.ready_replicas
        except Exception as e:
            print(json.loads(e.body)['message'])
            exit()

    else:
        try:
            api.list_namespaced_some_workload
        except Exception as e:
            print("Incorrect workload type. Please specify either deployment, statefulset, daemonset\n")
            exit()

def validate_types(**kwargs):
    if kwargs['type'] == "str":
        try:
            return re.match(r"^[a-z0-9]+-*[a-z0-9-]*[a-z0-9]+$", kwargs['var_value']).group()
        except:
            print("There was provided incorrect value for", kwargs['var_name'],  ". Alowed string starts and ends with a-z0-9 also consist '-' .Try again...")
            exit()
    elif kwargs['type'] == "int":
        try:
            return int(kwargs['var_value'])
        except ValueError:
            print("That was no valid number for variable", kwargs['var_name'], ". Try again...")
            exit()

def check(**kwargs):
    try:
      kwargs["check_timeout"]
    except KeyError:
      kwargs["check_timeout"] = 60
    try:
      kwargs["check_retries"]
    except KeyError:
      kwargs["check_retries"] = 10

    retries = validate_types(type="int", var_value=kwargs['check_retries'], var_name="check_retries")
    timeout = validate_types(type="int", var_value=kwargs['check_timeout'], var_name="check_timeout")
    workload_name = validate_types(type="str", var_value=kwargs['workload_name'], var_name="workload_name")
    workload_namespace = validate_types(type="str", var_value=kwargs['workload_namespace'], var_name="workload_namespace")
    workload_type = validate_types(type="str", var_value=kwargs['workload_type'], var_name="workload_type")

    for iterator in range(retries):

      desired_pods_int = desired_pods(workload_name=workload_name, workload_namespace=workload_namespace, workload_type=workload_type)
      ready_pods_int = ready_pods(workload_name=workload_name, workload_namespace=workload_namespace, workload_type=workload_type)

      if desired_pods_int == ready_pods_int:
          print("\n",workload_name,"pods are ready")
          exit(0)
      elif desired_pods_int > ready_pods_int:
          print(iterator,"th attempt, waiting", timeout, "sec for next one...")
          time.sleep(timeout)
      else:
          print("\n","Timeout is over but not all pods are ready")
          exit(1)