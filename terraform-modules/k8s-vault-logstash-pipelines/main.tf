resource "helm_release" "logstash" {
  for_each   = var.logstash_list
  name       = "logstash"
  namespace  = try(each.value.namespace, local.namespace)
  chart      = "${path.module}/logstash"
  wait         = true
  atomic       = true
  reset_values = true
  values     = [ file("${path.module}/logstash-values.yaml") ]
  set {
    name  = "extraEnvs"
    value = "{ \"USERNAME\": \"elastic\", \"PASSWORD\": \"test\" }"
  }
/*
    <<EOT
fullnameOverride: ${each.key}
extraEnvs:
  - name: 'ES_USER'
    value: '${local.es_user}'
  - name: 'ES_HOST'
    value: '${local.es_host}'
  - name: 'ES_PASSWORD'
    valueFrom:
      secretKeyRef:
        name: elastic-credentials-${each.key}
        key: password
  - name: MINIO_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: minio-credentials
        key: accesskey
  - name: MINIO_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: minio-credentials
        key: secretkey
extraVolumes:
  - name: elastic-credentials-${each.key}
    secret:
      defaultMode: 420
      items:
        - key: ca.crt
          path: ca.crt
      secretName: elastic-credentials-${each.key}
extraVolumeMounts:
  - name: elastic-credentials-${each.key}
    mountPath: /ssl-es/
logstashConfig:
  logstash.yml: |
    http.host: 0.0.0.0
    xpack.management.enabled: true
    xpack.management.logstash.poll_interval: ${local.poll_interval}
    xpack.management.elasticsearch.username: '${local.es_user}'
    xpack.management.elasticsearch.password: '$${ES_PASSWORD}'
    xpack.management.elasticsearch.hosts: ["${local.es_host}"]
    xpack.management.pipeline.id: ["${local.pipeline_id}"]
EOT
*/

  depends_on = [kubernetes_secret.elastic_credentials]
}

data "vault_generic_secret" "elastic_credentials" {
  for_each = var.logstash_list
  path     = "secret/logstash/${each.key}"
}

resource "kubernetes_secret" "elastic_credentials" {
  for_each = var.logstash_list
  metadata {
    name       = "elastic-credentials-${each.key}"
    namespace  = try(each.value.namespace, local.namespace)
  }

  data = {
    "ca.crt"  = data.vault_generic_secret.elastic_credentials[each.key].data.ca_cert,
    password   = data.vault_generic_secret.elastic_credentials[each.key].data.password
  }
}



#elastic7-es-http-certs-internal
#elastic7-es-elastic-user