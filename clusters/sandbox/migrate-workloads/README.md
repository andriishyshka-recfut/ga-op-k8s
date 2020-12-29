Here will be terraform code to spin up / migrate statefull / expose   workloads.


## Spin up workloads in inactive cluster.

## Migrate workloads from active to inactive



```
kuc gke_ardent-rarity-239115_us-east4_sandbox-blue
velero backup create harbor --include-resources pvc,pv --include-namespaces harbor  --wait
k get podvolumebackups.velero.io --all-namespaces
###
kuc gke_ardent-rarity-239115_us-east4_sandbox-green
velero restore create --from-backup harbor --wait
k get podvolumerestores.velero.io --all-namespaces

```
