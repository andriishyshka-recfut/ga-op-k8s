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
