resource "kubernetes_config_map" "cassandra_envs" {
  metadata {
    name      = "cassandra-envs"
    namespace = "cassandra"
  }
  data = {
    "cassandra-env.sh" = file("${path.module}/files/cassandra-env.sh")
  }
}

resource "kubernetes_config_map" "cassandra_init" {
  metadata {
    name      = "cassandra-init"
    namespace = "cassandra"
  }
  data = {
    "cassandra.cql" = file("${path.module}/files/cassandra.cql")
  }
}

data "vault_generic_secret" "cassandra" {
  path = "secret/cassandra/cassandra"
}

resource "kubernetes_secret" "cassandra_db_pass" {
  metadata {
    name      = "cassandra-db-password"
    namespace = "cassandra"
  }
  data = {
    "cassandra" = data.vault_generic_secret.cassandra.data["db-pass"]
  }
}

resource "helm_release" "cassandra" {
  name              = "cassandra"
  repository        = "https://charts.bitnami.com/bitnami"
  chart             = "cassandra"
  timeout           = 1800
  wait              = true
  atomic            = true
  namespace         = "cassandra"
  dependency_update = true
  set {
    name  = "replicaCount"
    value = "3"
  }
  set {
    name  = "dbUser.existingSecret.name"
    value = "cassandra-db-password"
  }
  set {
    name  = "dbUser.existingSecret.keyMapping.cassandra-password"
    value = "cassandra"
  }
  # set {
  #   name  = "dbUser.password"
  #   value = "1Q2w3e4r"
  # }
  set {
    name  = "initDBConfigMap"
    value = "cassandra-init"
  }
  set {
    name  = "existingConfiguration"
    value = "cassandra-envs"
  }
  # set {
  #   name  = "resources.requests.cpu"
  #   value = "2"
  # }
  # set {
  #   name  = "resources.requests.memory"
  #   value = "2Gi"
  # }
  depends_on = [
    kubernetes_config_map.cassandra_envs,
    kubernetes_config_map.cassandra_init,
    kubernetes_secret.cassandra_db_pass
  ]
}
