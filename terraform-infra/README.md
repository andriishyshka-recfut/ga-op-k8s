### Thist folder contains config for provisionning GKE cluster with terraform ans it's dependencies

# k8s



Inspired by https://github.com/GoogleCloudPlatform/gke-private-cluster-demo/blob/master/terraform

Steps to configure terraform :

1. Create a service account and download JSON with credentials
2. `export GOOGLE_CREDENTIALS=~/terraform-k8s-spin-up-6b41d9e8a44a.json`



Best pracitces accourding to [Scalable and Manageable: A Deep-Dive Into GKE Networking Best Practices](https://youtu.be/fI-5LkBDap8) :

1. Regional  cluster
2. VPC-Native
3. Max pods per node
4  use http load balancing
5. private cluster with cloud nat
6. master authorized networks for access



CNCF security projects:
- [falco](https://falco.org/docs/) can be used with [fluentd](https://sysdig.com/blog/kubernetes-security-logging-fluentd-falco/)



After cluster provision in we need to change ingress service type to nodeport:
```
k patch svc istio-ingressgateway --type=json -p="$(cat istio-ingress-patch.json)" --dry-run=true -o yaml -n istio-system | k apply -f -
```

And Label default namespace for autromatic sidecar injection:

```
k label namespace default istio-injection=enabled


k get svc istio-ingressgateway -n istio-system
k get nodes -o wide
```


Then we have to configure load_balancing to ingress NodePorts on Bastion host:
```
export Dport=80
export NodePort=30186
export NodeIp1=172.27.0.6
export NodeIp2=172.27.0.7
export NodeIp3=172.27.0.8

iptables -F OUTPUT -t nat


iptables -A OUTPUT -t nat -p tcp -d 10.0.0.1  --dport ${Dport} \
   -m statistic --mode random --probability 0.33  \
  -j DNAT --to-destination ${NodeIp1}:${NodePort}

iptables -A OUTPUT -t nat -p tcp -d 10.0.0.1  --dport ${Dport} \
   -m statistic --mode random --probability 0.33  \
  -j DNAT --to-destination ${NodeIp2}:${NodePort}

iptables -A OUTPUT -t nat -p tcp -d 10.0.0.1  --dport ${Dport} \
   -m statistic --mode random --probability 0.33  \
  -j DNAT --to-destination ${NodeIp3}:${NodePort}

```
Verify resource access over proxy:

```
curl nginx.example.com --resolve nginx.example.com:80:10.0.0.1 -x socks5://localhost:8080
```
