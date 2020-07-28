import sys
try:
    import json
except ImportError:
    import simplejson as json
import requests

input_json = sys.stdin.read()
try:
    input_dict = json.loads(input_json)
except ValueError as value_error:
    sys.exit(value_error)

out_dict = {}

r = requests.get('https://download.elastic.co/downloads/eck/'+input_dict["eck_version"]+'/all-in-one.yaml')

out_dict["crd"] = r.text


output_json = json.dumps(out_dict)
sys.stdout.write(output_json)
