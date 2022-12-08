locals {
  postInstallSteps = <<EOF
  curl -X POST "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_license" -H 'Content-Type: application/json' -k -d '
  ${data.vault_generic_secret.elastic_license.data[local.globalSettings.license.name]}
  ' &&\
  %{if var.Cluster == "sandbox"~}
  curl -X POST "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_security/role/developers" -H 'Content-Type: application/json' -k -d  '
  {
    "cluster":["all"],
     "indices":[{"names":"*","privileges":["all"]}]
  }
  ' &&\
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_security/role_mapping/saml-dev?pretty" -H 'Content-Type: application/json' -k -d '
{
  "roles": [  "developers" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "groups": "dev" } }
  ] }
}
  ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_security/role_mapping/saml-op" -H 'Content-Type: application/json' -k -d '
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "groups": "op" } }
  ] }
}
￼'
%{else~}
curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_security/role_mapping/saml-op" -H 'Content-Type: application/json' -k -d '
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "groups": "op" } }
  ] }
}
￼'
%{endif~}
EOF
}


resource "kubernetes_job" "post_install" {
  metadata {
    name      = "${local.globalSettings.clusterName}-post-install"
    namespace = local.globalSettings.namespace
  }
  spec {
    template {
      metadata {

        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name    = "post-install"
          image   = "curlimages/curl"
          command = ["sh", "-c", local.postInstallSteps]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "elastic-credentials"
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "100M"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on = [
    helm_release.elastic
  ]
  timeouts {
    create = "5m"
    update = "5m"
  }
}
