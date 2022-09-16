locals {
  tarantoolOperatorValues = yamldecode(file("${path.module}/tarantool-operator/values.yaml"))
}

resource "helm_release" "tarantool-operator" {
  name      = "tarantool-operator"
  chart     = "${path.module}/tarantool-operator"
  wait      = true
  atomic    = true
  namespace = "tarantool-operator"
  values = [
    yamlencode(local.tarantoolOperatorValues)
  ]
}

locals {
  tarantoolCartridgeValues = yamldecode(file("${path.module}/tarantool-cartridge/values.yaml"))
}

resource "helm_release" "tarantool-cartridge" {
  name      = "tarantool-cartridge"
  chart     = "${path.module}/tarantool-cartridge"
  wait      = true
  atomic    = true
  namespace = "tarantool"
  values = [
    yamlencode(local.tarantoolCartridgeValues)
  ]
}
