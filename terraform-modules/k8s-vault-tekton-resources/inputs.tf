variable "Resources" {}
variable "Settings" {}

locals {
  not_pipeline_list = [for resource in var.Resources : resource if resource != "pipeline.yaml"]
  pipeline_list = [for resource in var.Resources : resource if resource == "pipeline.yaml"]
  pipeline = templatefile("${path.module}/templates/pipeline.yaml.tftpl", { branch = var.Settings.DRBranch })
  not_pipeline_yaml = merge([
    for file in local.not_pipeline_list : {
      for i, d in split(
        "\n---\n",
        "\n${trimspace(file("${path.module}/resources/${file}"))}\n"
      ) :
      "${file}-${format("%02d", i)}" => trimspace(d)
      if trimspace(d) != ""
    }
  ]...)
  pipeline_yaml = {
    for i, d in split("\n---\n", "\n${trimspace(local.pipeline)}\n") :
    "pipeline-${format("%02d", i)}" => trimspace(d)
    if trimspace(d) != ""
  }
}
