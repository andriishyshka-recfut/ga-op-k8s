resource "kubernetes_manifest" "vault_issuer" {
  manifest = yamldecode(templatefile("${path.module}/../../templates/cert-manager/ClusterIssuer.tftpl", {
    Values = {
      name         = "vault-clickhouse"
      mountPath    = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
      vaultRole    = "cert-manager"
      secretName   = "sa-${var.Cluster}-cert-manager"
      vaultAddress = var.VaultAddress
      pkiPath      = local.tls.pki_mount
      pkiRole      = local.tls.pki_role
    }
  }))
}

locals {
  # Keeper's resource name already ends in -keeper; the operator appends it again.
  tls_services = {
    (local.tls_secret_name)        = "${local.cluster_name}-clickhouse-headless"
    (local.keeper_tls_secret_name) = "${local.keeper_name}-keeper-headless"
  }
  tls_dns_suffixes = ["", ".${local.namespace}", ".${local.namespace}.svc", ".${local.namespace}.svc.cluster.local"]
  clickhouse_internal_services = flatten([
    for shard in range(local.shards) : [
      for replica in range(local.replicas) : "${local.cluster_name}-clickhouse-internal-${shard}-${replica}"
    ]
  ])
  tls_dns_names = {
    for name, service in local.tls_services : name => concat(
      flatten([for suffix in local.tls_dns_suffixes : ["${service}${suffix}", "*.${service}${suffix}"]]),
      name == local.tls_secret_name ? flatten([
        for internal_service in local.clickhouse_internal_services : [
          for suffix in local.tls_dns_suffixes : "${internal_service}${suffix}"
        ]
      ]) : [],
    )
  }
}

resource "kubernetes_manifest" "certificate" {
  for_each = local.tls_services

  manifest = yamldecode(templatefile("${path.module}/../../templates/cert-manager/Certificate.tftpl", {
    Values = {
      name        = each.key
      namespace   = local.namespace
      secretName  = each.key
      commonName  = local.tls_dns_names[each.key][0]
      issuerName  = "vault-clickhouse"
      issuerKind  = "ClusterIssuer"
      duration    = "720h"
      renewBefore = "48h"
      dnsNames    = local.tls_dns_names[each.key]
    }
  }))

  depends_on = [kubernetes_manifest.vault_issuer]
}
