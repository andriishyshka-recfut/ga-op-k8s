resource "kubernetes_persistent_volume" "kafka_data_pv" {
  count = local.pv_disk_count
  metadata {
    name = "kafka-data-${count.index}-pv"
    labels = {
      target = "kafka-data"
    }
  }
  spec {
    capacity = {
      storage = local.diskSize
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.kafkaNs
      name = "data-0-kafka-cluster-kafka-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/regions/${var.Settings.clusters[var.Cluster].region}/disks/kafka-data-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ "us-east4-a", "us-east4-b"]            
          }
        }
      }
    }
  }
}



resource "kubernetes_persistent_volume" "kafka_zookeeper_pv" {
  count = local.pv_disk_count
  metadata {
    name = "kafka-zookeeper-${count.index}-pv"
    labels = {
      target = "kafka-zookeeper"
    }
  }
  spec {
    capacity = {
      storage = local.diskSize
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.kafkaNs
      name = "data-kafka-cluster-zookeeper-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/regions/${var.Settings.clusters[var.Cluster].region}/disks/kafka-zookeeper-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ "us-east4-a", "us-east4-b"]            
          }
        }
      }
    }
  }
}


resource "helm_release" "kafka_operator" {
  name       = "kafka-operator"
  chart      = "strimzi-kafka-operator"
  repository = "https://strimzi.io/charts/"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  timeout    = 900
  version    = "0.25.0"
}


resource "helm_release" "kafka_cluster" {
  name      = "kafka-cluster"
  chart     = "${path.module}/kafka"
  namespace = local.kafkaNs
  wait      = true
  atomic    = true
  set {
    name = "subdomain"
    value = "${var.Settings.clusters[var.Cluster].subdomain}.${var.Settings.clusters[var.Cluster].domain}"
  }
  set {
    name = "diskSize"
    value = local.diskSize
  }
  set {
    name = "usePV"
    value = local.use_pv
  }
  set {
    name = "cpuReuest"
    value = local.request.cpu
  }
  set {
    name = "memReuest"
    value = local.request.memory
  }
  set {
    name = "memLimit"
    value = local.limit.memory
  }
  set {
    name = "cpuLimit"
    value = local.limit.cpu
  }
  depends_on = [
    helm_release.kafka_operator,
  ]
}

resource "null_resource" "ansible_wait_for_kafka" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
    kafka_id          = helm_release.kafka_cluster.id
    kafka_operator_id = helm_release.kafka_operator.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook k8s-wait-for.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name           = "kafka-cluster"
      kind           = "kafka"
      namespace      = local.kafkaNs
      apiVersion     = "kafka.strimzi.io/v1beta2"
      statusPath     = "conditions[1].type"
      requiredStatus = "Ready"
    })
  }
  depends_on = [
    helm_release.kafka_cluster
  ]
}
