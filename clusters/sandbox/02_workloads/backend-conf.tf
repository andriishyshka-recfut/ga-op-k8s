


terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-workloads/state-9"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }

}
output "ActiveCluster" {
  value = local.activeCluster
}
