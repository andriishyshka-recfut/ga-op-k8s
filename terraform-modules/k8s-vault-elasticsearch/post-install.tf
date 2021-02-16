locals {
  postInstallSteps = <<EOF
  curl -XPOST "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_license/start_trial?acknowledge=true" -k &&\
  curl -X POST "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role/oidc_ro" -H 'Content-Type: application/json' -k -d  '
{
  "cluster":["monitor"],
   "indices":[{"names":"*","privileges":["read","view_index_metadata"]}]
}
  ' &&\
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-example?pretty" -H 'Content-Type: application/json' -k -d '
{
  "roles": [  "kibana_user","oidc_ro","monitoring_user" ],
  "enabled": true,
  "rules": {
    "field": { "realm.name": "${local.oidcRealmName}" }
  }
}
' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-dc" -H 'Content-Type: application/json' -k -d '
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "realm.name": "google" } },
        { "field": { "username": "dc@geminiadvisory.io" } }
  ] }
}
￼' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-sb" -H 'Content-Type: application/json' -k -d '
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "realm.name": "google" } },
        { "field": { "username": "stepan.biriukov@geminiadvisory.io" } }
  ] }
}
￼' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-anton" -H 'Content-Type: application/json' -k -d '
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "realm.name": "google" } },
        { "field": { "username": "anton.moliavko@geminiadvisory.io" } }
  ] }
}
￼'
EOF
}

resource "kubernetes_job" "post_install" {
  count = local.oidcSetup
  metadata {
    name      = "${local.esValues.esName}-post-install"
    namespace = local.esValues.namespace
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
                name = "${local.esValues.esName}-es-elastic-user"
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "10m"
              memory = "10M"
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
    null_resource.ansible_validate_resources
  ]
  timeouts {
    create = "5m"
    update = "5m"
  }
}
