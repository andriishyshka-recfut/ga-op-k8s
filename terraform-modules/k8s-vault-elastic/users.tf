locals {
  postInstallSteps = <<EOF
  curl -XPOST "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_license/start_trial?acknowledge=true" -k &&\
  curl -X POST "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role/oidc_ro" -H 'Content-Type: application/json' -k -d  '
{
  "cluster":["monitor"],
   "indices":[{"names":"*","privileges":["read","view_index_metadata"]}]
}
  ' &&\
  curl -X POST "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role/developers" -H 'Content-Type: application/json' -k -d  '
  {
    "cluster":["monitor"],
     "indices":[{"names":"*","privileges":["all"]}]
  }
  ' &&\
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-dev?pretty" -H 'Content-Type: application/json' -k -d '
{
  "roles": [  "viewer","monitoring_user" ],
  "enabled": true,
  "rules": { "all": [
        { "field": { "realm.name": "google" } },
        { "field": { "username": "anton@geminiadvisory.io" } },
        { "field": { "username": "valerii.korolov@geminiadvisory.io" } },
        { "field": { "username": "askat.abdikary@geminiadvisory.io" } },
        { "field": { "username": "eugene@geminiadvisory.io" } },
        { "field": { "username": "nikita.leonov@geminiadvisory.io" } },
        { "field": { "username": "vladyslav.martynenko@geminiadvisory.io" } },
        { "field": { "username": "mykhailo.kalashnikov@geminiadvisory.io" } },
        { "field": { "username": "serhii.hutsaliuk@geminiadvisory.io" } }
  ] }
}
' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-am?pretty" -H 'Content-Type: application/json' -k -d '
{
"roles": [ "superuser" ],
"enabled": true,
"rules": { "all": [
      { "field": { "realm.name": "google" } },
      { "field": { "username": "anton.moliavko@geminiadvisory.io" } }
] }
}
curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-dc?pretty" -H 'Content-Type: application/json' -k -d '
{
"roles": [ "superuser" ],
"enabled": true,
"rules": { "all": [
      { "field": { "realm.name": "google" } },
      { "field": { "username": "dc@geminiadvisory.io" } }
] }
}
curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-dk?pretty" -H 'Content-Type: application/json' -k -d '
{
"roles": [ "superuser" ],
"enabled": true,
"rules": { "all": [
      { "field": { "realm.name": "google" } },
      { "field": { "username": "dmytro.kubov@geminiadvisory.io" } }
] }
}
  ' &&\
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-ro?pretty" -H 'Content-Type: application/json' -k -d '
{
  "roles": [  "viewer","monitoring_user" ],
  "enabled": true,
  "rules": {
    "field": { "realm.name": "${local.oidcRealmName}" }
  }
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
