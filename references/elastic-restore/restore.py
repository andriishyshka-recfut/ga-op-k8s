import json
import requests
import sys
import os
import time
from requests.auth import HTTPBasicAuth

# input = sys.stdin.read()
# input_json = json.loads(input)

# username = input_json.get("ELASTICSEARCH_USERNAME")
# password = input_json.get("ELASTICSEARCH_PASSWORD")
# elasticurl = input_json.get("ELASTICSEARCH_URL")
# ca = input_json.get("CA_CERT").replace('\\n','\n') if "CA_CERT" in input_json else ""
# snapshots = input_json.get("SNAPSHOTS").split(',') if "SNAPSHOTS" in input_json else []
# sleep_time = input_json.get("SLEEP_TIME") if  "SLEEP_TIME" in input_json else 60
# wait_for_completion = input_json.get("WAIT_FC") if "WAIT_FC" in input_json else "false"
# repository = input_json.get("REPOSITORY") if "REPOSITORY" in input_json else "minio"
# ca_verify = input_json.get("CHECK_SSL") if "CHECK_SSL" in input_json else True
username = os.getenv('ELASTICSEARCH_USERNAME')
password = os.getenv('ELASTICSEARCH_PASSWORD')
elasticurl = os.getenv('ELASTICSEARCH_URL')
ca = os.getenv('CA_CERT',default="").replace('\\n','\n')
snapshots = os.getenv("SNAPSHOTS",default=[]).split(',')
sleep_time = os.getenv("SLEEP_TIME",default=60)
repository = 'minio'
wait_for_completion = os.getenv("WAIT_FC",default=False)
ca_verify = os.getenv("CHECK_SSL",default=True)

basic = HTTPBasicAuth(username,password)

certca = open("ca.pem","w")
certca.write(ca)
certca.close()
if ca_verify == True:
    ca_path = './ca.pem'
else:
    ca_path = False

def http_response(code):
    if code == 200:
        message = "Request was successful"
    elif code == 401:
        message = "You are not authorized (check username and password)"
    else:
        message = f"Something wrong - response code is {code}"
    return message

def logs(json_data):
    out = {}
    for element in json_data:
        out[element] = str(json_data[element])
    sys.stdout.write(json.dumps(out))
    sys.stdout.write('\n')

def do_request(name,request_type="get",include_global_state="false",print_state=True):
    msg = {}
    try:
        if request_type == "recover":
            url = 'https://' + elasticurl + "/_snapshot/" +  repository + "/" + name + "/_restore?wait_for_completion=false"
            req_data = { "include_global_state": include_global_state }
            site_request = requests.post(url, verify=ca_path, auth=basic, json= req_data)
        if request_type == "status":
            url = 'https://' + elasticurl + '/_recovery'
            site_request = requests.get(url, verify=ca_path, auth=basic)
        else:
            url = 'https://' + elasticurl + "/_snapshot/" +  repository + "/" + name
            site_request = requests.get(url, verify=ca_path, auth=basic)
    except Exception as e:
        msg["message"] = str(e)
        logs(msg)
        sys.exit(1)
    else:
        if print_state:
            msg["request_type"] = str(request_type.strip())
            msg["message"] = str(http_response(site_request.status_code).strip())
            logs(msg)
        if site_request.status_code != 200:
            msg["message"] = str(site_request.text.strip())
            logs(msg)
            sys.exit()
        return site_request

def check_shards(response):
    for restore_index in index_list:
        shards_state = True
        for shard in response[restore_index]["shards"]:
            if shard["type"] == "SNAPSHOT":
                if shard["stage"] != 'DONE':
                    shards_state = False
        if shards_state:
            index_list[restore_index] = True

if len(snapshots) > 0:
    for snapshot in snapshots:
        index_list = {}
        get_snapshot_info = do_request(snapshot).json()
        if get_snapshot_info["snapshots"][0]["include_global_state"]:
            global_state = "true"
        else:
            global_state = "false"
        restore = do_request(snapshot,"recover",global_state).json()
        recovery_indexes = do_request(snapshot,"status").json()
        if wait_for_completion:
            wait_count = 0
            for index,value in recovery_indexes.items():
                if value["shards"][0]["type"] == "SNAPSHOT":
                    if value["shards"][0]["source"]["snapshot"] == snapshot:
                        index_list[index] = False
            check_shards(recovery_indexes)
            while sum([*index_list.values()]) < len([*index_list.values()]):
                msg ={}
                wait_state = do_request(snapshot,"status",print_state=False).json()
                check_shards(wait_state)
                wait_count += 1
                msg["snapshot"] = str(snapshot)
                msg["count"] = str(wait_count)
                msg["state"] = str("Not Finished")
                logs(msg)
                time.sleep(sleep_time)
        msg = {}
        msg["snapshot"] = str(snapshot)
        msg["state"] = "Done"
        logs(msg)
os.remove("ca.pem")
