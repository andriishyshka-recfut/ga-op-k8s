resource "null_resource" "stop_istio_lb" {

  triggers = {
    command = md5(local.delete_lb_service)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_lb_service
  }
}
resource "null_resource" "stop_internal_ingress" {

  triggers = {
    command = md5(local.delete_internal_ingress)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_internal_ingress
  }
}