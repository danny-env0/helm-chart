resource "helm_release" "agent" {
  name             = "env0-agent-${var.stage}"
  namespace        = "env0-agent-${var.stage}"
  create_namespace = true
  chart            = path.module
  timeout          = 600
  wait             = var.wait_for_resources
  values = [
    var.helm_values != null ? var.helm_values : file("${path.module}/values.yaml"),
    yamlencode({
      force_helm_upgrade : uuid()
    })
  ]
}
