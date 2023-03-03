import json

import hvac
import os
import requests

multiregion_buckets = {
    'ardent-rarity-239115-gitlab-snapshots': 'gitlab-snapshots-ardent-rarity',
    'ardent-rarity-239115-gitlab-tmp': 'gitlab-tmp-ardent-rarity',
    'es-backup-asdsafawdgasd': 'es-backup-ardent-rarity',
    'harbor-backet-ardent-rarity-239115': 'harbor-backet-ardent-rarity',
    'kubescape-reports-ardent-rarity': 'kubescape-reports-ardent-rarity2',
    'minio-dome-attachements-ardent-rarity-239115': 'minio-dome-attachements-ardent-rarity',
    'minio-es7-ardent-rarity-239115': 'minio-es7-ardent-rarity',
    'minio-logstash-pipelines-ardent-rarity-239115': 'minio-logstash-pipelines-ardent-rarity',
    'minio-magescanner-geoip-ardent-rarity-239115': 'minio-magescanner-geoip-ardent-rarity',
    'minio-magescanner-har-ardent-rarity-239115': 'minio-magescanner-har-ardent-rarity',
    'minio-magescanner-hash-ardent-rarity-239115': 'minio-magescanner-hash-ardent-rarity',
    'minio-magescanner-scan-ardent-rarity-239115': 'minio-magescanner-scan-ardent-rarity',
    'minio-magescanner-splash-ardent-rarity-239115': 'minio-magescanner-splash-ardent-rarity',
    'minio-maid-ardent-rarity-239115': 'minio-maid-ardent-rarity',
    'minio-meganz-migrate-ardent-rarity-239115': 'minio-meganz-migrate-ardent-rarity',
    'minio-xbackup-ardent-rarity-239115': 'minio-xbackup-ardent-rarity',
    'minio-xdebug-ardent-rarity-239115': 'minio-xdebug-ardent-rarity',
    'thanos-ardent-rarity-239115': 'thanos-ardent-rarity',
    'vault-asasfasfdasf': 'vault-ardent-rarity'
}


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
                            new_value = value.replace(bucket, multiregion_buckets[bucket])
                            print("New value for {}:\n\t{}".format(key, new_value))
                            # client.secrets.kv.v2.patch(path=path, secret={key:new_value},)
            except hvac.exceptions.InvalidPath:
                i = 0
                # print("\t* Failed to retrieve secret {}".format(path))


client = hvac.Client(
    url=os.environ['VAULT_ADDR'],
    token=os.environ['VAULT_TOKEN']
)

if client.is_authenticated():
    print("Auth done")
    check_items("")
