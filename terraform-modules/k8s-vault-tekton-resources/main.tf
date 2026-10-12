#Left this resource for debug
# resource "local_file" "pipeline" { 
#   content = templatefile("${path.module}/templates/pipeline.yaml.tftpl", { branch = var.Settings.DRBranch }) 
#   filename = "${path.module}/resources/pipeline.yaml" 
# }

resource "kubectl_manifest" "tekton_resource_pipeline" {
  for_each  = local.pipeline_yaml
  yaml_body = each.value
}
resource "kubectl_manifest" "tekton_resource" {
  for_each  = local.not_pipeline_yaml
  yaml_body = each.value
  depends_on = [ kubectl_manifest.tekton_resource_pipeline ]
}