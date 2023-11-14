import requests
import sys
import os
from requests.auth import HTTPBasicAuth

#envs
templates = os.getenv('TEMPLATES')
certca = '/etc/ssl/ca.crt'
username = os.getenv('ELASTICSEARCH_USERNAME')
password = os.getenv('ELASTICSEARCH_PASSWORD')
elasticurl = os.getenv('ELASTICSEARCH_URL')
filebeatversion = os.getenv("FILEBEAT_VERSION")
requests_actions = {"check":"get","save":"put","ilm":"put","index":"put"}
basic = HTTPBasicAuth(username,password)

ilm_template = {
    "policy" : {
        "phases" : {
            "hot" : {
                "min_age" : "0ms",
                "actions" : {
                    "rollover" : {
                        "max_primary_shard_size" : "50gb",
                        "max_age" : "1d"
                    },
                    "set_priority" : {
                        "priority" : 100
                    }
                }
            },
            "delete" : {
                "min_age" : "90d",
                "actions" : {
                    "delete" : {
                        "delete_searchable_snapshot" : 'true'
                    }
                }
            }
        }
    }
}


def prepare_template_name(templates, filebeat_version):
    return_templates = []
    for name in templates.split(','):
        return_templates.append("filebeat-" + name + '-' + filebeat_version)
    return return_templates

def http_response(code):
    if code == 200:
        message = "Request was successful"
    elif code == 401:
        message = "You are not authorized (check username and password)"
    else:
        message = f"Something wrong - response code is {code}"
    return message

def do_request(request_type,template=None,name=None,ilm=None, index=None):
    if request_type in requests_actions:
        try:
            if request_type == "check":
                url = 'https://' + elasticurl + "/_index_template"
                site_request = requests.get(url, verify=certca, auth=basic)
            elif request_type == "save":
                url = 'https://' + elasticurl + "/_index_template/" + name
                site_request = requests.put(url, json=template, verify=certca, auth=basic)
            elif request_type == "ilm":
                url = 'https://' + elasticurl + "/_ilm/policy/" + short_name(name)
                site_request = requests.put(url, json=ilm, verify=certca, auth=basic)
            elif request_type == "index":
                url = 'https://' + elasticurl + '/%3C' + name + '-%7Bnow%2Fd%7D-000001%3E'
                site_request = requests.put(url, json=index, verify=certca, auth=basic)
        except Exception as e: 
            print('{"message":"',e,'"}')
            sys.exit()
        else:
            print ('{"request_type":"',request_type.strip(),'","message":"',http_response(site_request.status_code).strip(),'"}')
            if site_request.status_code != 200:
                print('{"message":"',site_request.text.strip(),'"}')
                sys.exit()
            return site_request

def short_name(name):
    short_name = '-'.join(name.split('-')[:-1])
    return short_name

def update_template(template,name):
    template["index_template"]["index_patterns"][0] = name + "-*"
    template["index_template"]["template"]["settings"]["index"]["lifecycle"]["name"] = short_name(name)
    template["index_template"]["template"]["settings"]["index"]["lifecycle"]["rollover_alias"] = short_name(name)
    new_template = template["index_template"]
    return new_template

check = do_request("check").json()
work_templates = prepare_template_name(templates, filebeatversion)
site_templates = []
filebeat_template = {}
for template in check["index_templates"]:
    site_templates.append(template["name"])
    if template["name"] == "filebeat-" + filebeatversion:
        filebeat_template = template

for template in work_templates:
    if template not in site_templates:
        print(template)
        new_template = update_template(filebeat_template,template)
        do_request("save", new_template, template)
        do_request("ilm", name=template, ilm=ilm_template)
        index_template = {"aliases": {short_name(template): {"is_write_index": 'true' }}}
        do_request("index", name=template, index=index_template)
        

