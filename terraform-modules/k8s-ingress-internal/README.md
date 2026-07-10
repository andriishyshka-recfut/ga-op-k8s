# k8s-ingress-internal

This module supports two ways to resolve the IP address for `ingress-internal` entries:

- `ip`: use the IP value directly
- `ip_link`: resolve the IP from `Settings.internal_static_ips`

Resolution order after the latest change:

1. If `ip` is set, the module uses it as-is.
2. If `ip` is not set and `ip_link` is set, the module uses `Settings.internal_static_ips[ip_link]`.
3. If neither `ip` nor `ip_link` is set, the module keeps the previous behavior and falls back to `Settings.internal_static_ips[resource_name]`.

Examples:

```hcl
"beat-minion" = {
  ip_link     = "beat-minion"
  namespace   = "core"
  port        = 9080
  target_port = 9080
}
```

```hcl
"minio" = {
  ip_link     = "minio-helm"
  service     = true
  namespace   = "minio-helm"
  port        = 9000
  target_port = 9000
}
```

```hcl
"bastion" = {
  ip          = "172.23.0.4"
  service     = true
  namespace   = "monitoring"
  port        = 9100
  target_port = 9100
}
```
