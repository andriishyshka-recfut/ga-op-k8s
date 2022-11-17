## Utility to compare topics betweek kafka clusters

### Install dependencies:
```
pip3 install -r requirements.txt
```


### Setup service forwarding to new k8s cluster (i.e. when broker alias still pointing to old environment):
```
kubectl config get-contexts
kubectl config use-context <new k8s cluster>
sudo -E kubefwd svc -n kafka
```

### Usage

```commandline
python3 main.py -s <source broker> -t <target broker>
```
This will display only topics in which size or lag is different from source.
If you wish to see all topics add `-a` flag

example:
```commandline
python3 main.py -s broker-0.p.regemini.io:32200 -t kafka-cluster-kafka-0.kafka-cluster-kafka-brokers:9092
```