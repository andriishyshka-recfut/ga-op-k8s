locals {
  redisCommanderRo = {
    configMapName = "redis-commander-sentinels-ro"
  }
}
variable "RedisSettings" {}

resource "kubernetes_config_map" "redis_commander" {
  metadata {
    name      = "redis-commander-sentinels"
    namespace = "redis-operator-ns"
  }
  data = {
    "connections.json" = "${file("${path.module}/connections.json")}"
  }
}

resource "kubernetes_config_map" "redis_commander_ro" {
  metadata {
    name      = "redis-commander-sentinels-ro"
    namespace = "redis-operator-ns"
  }
  data = {
    "connections.json" = "${file("${path.module}/connections-ro.json")}"
  }
}


resource "helm_release" "redis" {
  for_each     = var.RedisSettings
  name         = "redis"
  chart        = "${path.module}/charts/redis"
  wait         = true
  atomic       = true
  namespace    = each.value["ns"]
  reset_values = true
  values       = [templatefile("${path.module}/templates/redis.tftpl", { Settings = each.value })]
  depends_on   = [helm_release.operator]
}

resource "helm_release" "redis_commander" {
  name      = "redis-commander"
  chart     = "${path.module}/charts/redis-commander"
  wait      = true
  atomic    = true
  namespace = "redis-operator-ns"
  values    = [templatefile("${path.module}/templates/redis-commander.tftpl", { Settings = {} })]
}
resource "helm_release" "redis_commander_ro" {
  name      = "redis-commander-ro"
  chart     = "${path.module}/charts/redis-commander"
  wait      = true
  atomic    = true
  namespace = "redis-operator-ns"
  values    = [templatefile("${path.module}/templates/redis-commander.tftpl", { Settings = local.redisCommanderRo })]
}

resource "kubernetes_service" "redis_core_nodeport" {
  count = var.Color == "red" ? 0 : 1
  metadata {
    name      = "redis-core-nodeport"
    namespace = "core"
  }
  spec {
    selector = {
      "statefulset.kubernetes.io/pod-name" = "rfr-redisfailover-0"
    }
    port {
      name        = "nodeportredis"
      port        = 6379
      target_port = 6379
      node_port   = 32305
      protocol    = "TCP"
    }
    type = "NodePort"
  }
}
