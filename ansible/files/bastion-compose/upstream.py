import requests
import os
import sys, logging
from jinja2 import Template
import time

# Set logging to json and stdout. Should be enough for docker
logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="{'time':'%(asctime)s', 'name': '%(name)s', \
    'level': '%(levelname)s', 'message': '%(message)s'}")


def do_stuff(api_endpoint,upstream_file,node_port,cluster_name):
    # list nodes in particular k8s cluster
    r = requests.get(api_endpoint +'/api/v1/nodes', verify=False)

    addresses = [ item['status']['addresses'] for item in r.json()['items'] ]

    InternalIP = []

    for address in addresses:
        for item in address:
            if item["type"]=="InternalIP":
                InternalIP.append(item["address"])


    t = Template("""upstream {{ cluster_name }}_backend {
{% for server in InternalIP -%}
    server {{ server }}:{{ nodePort }} ;
{% endfor %}
}
map $remote_addr $backend {
{% for server in InternalIP -%}
    ~{{ loop.index }}$ {{ server }} ;
{% endfor %}
    default {{ InternalIP[0] }} ;
}
server {
listen  30000-30020;
proxy_pass $backend:$server_port ;
}
""")
    render = t.render(cluster_name=cluster_name,InternalIP=InternalIP,nodePort=node_port)
    read = ""

    try:
        with open(upstream_file,"r+", encoding="ascii") as f:
            read = f.read()
        if render  != read :
            logging.info("Upstream drift detected. updatring from: \n "+str(read)+"\n to: \n " + str(render))
            with open(upstream_file,"w+", encoding="ascii") as f:
                f.write( render )
    except FileNotFoundError:
        with open(upstream_file,"w+",encoding="ascii") as f:
            logging.info("No upstream file "+ upstream_file \
                         +" found. Creating new one with next content: \n "\
                         + str(render))
            f.write( render )

def main():
    while True:
        do_stuff(api_endpoint=os.environ.get('HOST'),
                 upstream_file=os.environ.get('UPSTREAM_FILE'),
                 node_port=os.environ.get('NODE_PORT'),
                 cluster_name=os.environ.get('SUBDOMAIN'))
        time.sleep(60)


if __name__ == "__main__":
    main()
