import json
import hvac
import os
import requests
import sys

def list_secrets(folder):
    url = "{}/v1/secret/metadata/{}".format(os.environ['VAULT_ADDR'], requests.utils.quote(folder, safe=''))
    # print(url)

    headers = {"X-Vault-Token": os.environ['VAULT_TOKEN']}
    res = requests.get(url, params={"list": "true"}, headers=headers).content
    children = json.loads(res)["data"]["keys"]
    # print("\t", children)
    return children


def check_items(parent):
    child_items = list_secrets(parent)
    for child in child_items:
        path = parent + child
        if child[-1] == '/':
            # print(path)
            check_items(path)
        else:
            try:
                secret_version_response = client.secrets.kv.v2.read_secret_version(
                    path=path,
                )
                # print('\t* {} keys: {}'.format(path, secret_version_response['data']['data'].keys(),))
                for secret in secret_version_response['data']['data'].items():
                    for bucket in multiregion_buckets.keys():
                        if bucket in str(secret):
                            print("- Found bucket {} in secret {}:\n\t{}".format(bucket, path, secret))
                            key = secret[0]
                            value = secret[1]
                            new_value = value.replace(old_color, new_color)
                            # print("New value for {}:\n\t{}".format(key, new_value))
                            client.secrets.kv.v2.patch(path=path, secret={key:new_value},)
            except hvac.exceptions.InvalidPath:
                i = 0
                # print("\t* Failed to retrieve secret {}".format(path))


new_color = sys.argv[1]
old_color = "blue" if new_color == "green" else "green"

client = hvac.Client(
    url=os.environ['VAULT_ADDR'],
    token=os.environ['VAULT_TOKEN']
)

if client.is_authenticated():
    print("Auth done")
    check_items("mongo/")
