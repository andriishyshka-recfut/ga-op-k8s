resource "kubernetes_manifest" "vault_issuer" {
  count = local.tls.enabled ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/../../templates/cert-manager/ClusterIssuer.tftpl", {
    Values = {
      name         = local.tls.issuer_name
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
  tls_dns_suffixes = ["", ".${local.namespace}", ".${local.namespace}.svc", ".${local.namespace}.svc.cluster.local"]
  tls_hosts = {
    (local.pgpool_tls_secret_name) = ["${local.cluster_name}-pgpool"]
    (local.postgresql_tls_secret_name) = concat(
      ["${local.cluster_name}-postgresql", "${local.cluster_name}-postgresql-headless"],
      [
        for i in range(local.postgres_ha_settings.replicas) :
        "${local.cluster_name}-postgresql-${i}.${local.cluster_name}-postgresql-headless"
      ],
    )
  }
  tls_dns_names = {
    for name, hosts in local.tls_hosts : name => flatten([
      for host in hosts : [for suffix in local.tls_dns_suffixes : "${host}${suffix}"]
    ]) if local.tls.enabled
  }
}

resource "kubernetes_manifest" "certificate" {
  for_each = local.tls_dns_names

  manifest = yamldecode(templatefile("${path.module}/../../templates/cert-manager/Certificate.tftpl", {
    Values = {
      name        = each.key
      namespace   = local.namespace
      secretName  = each.key
      commonName  = each.value[0]
      issuerName  = local.tls.issuer_name
      issuerKind  = "ClusterIssuer"
      duration    = local.tls.duration
      renewBefore = local.tls.renew_before
      dnsNames    = each.value
    }
  }))

  # Wait for issuance, not just creation of the Certificate resource.
  wait {
    fields = {
      "status.conditions[?(@.type=='Ready')].status" = "True"
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
  }

  depends_on = [kubernetes_manifest.vault_issuer]
}
