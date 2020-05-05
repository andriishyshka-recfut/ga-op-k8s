### Here are set of commands to execute after cluster provisioning



https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html
pip3 install google-auth --user


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
