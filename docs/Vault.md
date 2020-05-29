### Requirements to cluster

 * HA Support (not all storage support HA)
 * Redundant storage ([GCS](https://www.vaultproject.io/docs/configuration/storage/google-cloud-storage) is)
 * Auto unsealing with Google KMS ???
 * OIDC auth
 * Will need to choose [operator](https://operatorhub.io/operator/vault) deploy or [helm](https://www.vaultproject.io/docs/platform/k8s/helm/run)

[Terraform example from Seth Vargo](https://github.com/sethvargo/vault-on-gke/blob/master/terraform/gcp.tf)


[Failure Scenarios](https://www.hashicorp.com/resources/adopting-hashicorp-vault/s)

 * In case of an individual node failure, or up to two node failures, the solution will continue to run without operator intervention.
 * If the Vault cluster fails, it can be reprovisioned using the same Storage Backend configuration.
 * If the Consul cluster were to lose quorum, there are alternatives to regain service availability, although the recommended approach from an RTO/RPO perspective is to fail over to a DR Cluster or promote a Performance Replica.
 * If the Seal Key was to be deleted or unavailable, the only supported scenario is failing over to a DR Cluster or Performance Replica
