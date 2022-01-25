locals {
  redisValues          = yamldecode(file("${path.module}/charts/redis/values.yaml"))
  redisCommanderValues = yamldecode(file("${path.module}/charts/redis-commander/values.yaml"))
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
  for_each  = var.RedisSettings
  name      = "redis"
  chart     = "${path.module}/charts/redis"
  wait      = true
  atomic    = true
  namespace = each.value["ns"]
  values = [
    yamlencode(local.redisValues)
  ]
  set {
    name  = "redisCrd.enabled"
    value = lookup(each.value, "redis-crd", true)
  }
  set {
    name  = "redisService.enabled"
    value = lookup(each.value, "redis-service", true)
  }
  set {
    name  = "rediscommDeployment.enabled"
    value = lookup(each.value, "rediscomm-deplyment", true)
  }
  set {
    name  = "rediscommService.enabled"
    value = lookup(each.value, "rediscomm-service", true)
  }
  set {
    name  = "redisCrd.sentinel.replicas"
    value = lookup(each.value, "sentinel-repl", 3)
  }
  set {
    name  = "redisCrd.redis.replicas"
    value = lookup(each.value, "redis-repl", 3)
  }
  set {
    name  = "redisCrd.sentinel.resources.requests.cpu"
    value = lookup(each.value, "sentinel-req-cpu", "100m")
  }
  set {
    name  = "redisCrd.sentinel.resources.limits.memory"
    value = lookup(each.value, "sentinel-lim-mem", "100Mi")
  }
  set {
    name  = "redisCrd.redis.resources.requests.cpu"
    value = lookup(each.value, "redis-req-cpu", "100m")
  }
  set {
    name  = "redisCrd.redis.resources.requests.memory"
    value = lookup(each.value, "redis-req-mem", "100Mi")
  }
  set {
    name  = "redisCrd.redis.resources.limits.cpu"
    value = lookup(each.value, "redis-lim-cpu", "400m")
  }
  set {
    name  = "redisCrd.redis.resources.limits.memory"
    value = lookup(each.value, "redis-lim-mem", "500Mi")
  }
  depends_on = [helm_release.operator]
}

resource "helm_release" "redis_commander" {
  name      = "redis-commander"
  chart     = "${path.module}/charts/redis-commander"
  wait      = true
  atomic    = true
  namespace = "redis-operator-ns"
  values = [
    yamlencode(local.redisCommanderValues)
  ]
}
resource "helm_release" "redis_commander_ro" {
  name      = "redis-commander-ro"
  chart     = "${path.module}/charts/redis-commander"
  wait      = true
  atomic    = true
  namespace = "redis-operator-ns"
  values = [
    yamlencode(local.redisCommanderValues)
  ]
  set {
    name  = "Deployment.configMapName"
    value = "redis-commander-sentinels-ro"
  }
}
