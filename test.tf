resource "null_resource" "helm_test_agent" {
  depends_on = [helm_release.agent]

  triggers = {
    name       = helm_release.agent.name
    namespace  = helm_release.agent.namespace
    repository = helm_release.agent.repository
    values     = jsonencode(helm_release.agent.values)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = nonsensitive(local.kubeconfig)
    }

    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
if [[ ! \"${var.stage}\" =~ \"pr[0-9]*\" ]]; then
  echo "Running Helm tests"
  date
  curl -LJO https://get.helm.sh/${local.helm_tar} &&
  tar -zxvf ${local.helm_tar} &&
  mkdir op &&
  mv ${local.os_arch}/helm op/helm &&
  echo "$KUBECONFIG" > op/kubeconfig
  chmod 611 op/kubeconfig
  export KUBECONFIG=op/kubeconfig
  op/helm test -n ${helm_release.agent.namespace} ${helm_release.agent.name}  --logs --timeout 2m
  date
  echo "Finished Helm test"
else
  echo "Skipping Helm tests because this is a PR build"
fi
EOF
  }
}

data "aws_eks_cluster" "cluster" {
  name = var.aws_eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.aws_eks_cluster_name
}

locals {
  os_arch    = "linux-amd64"
  helm_tar   = "helm-v3.7.2-${local.os_arch}.tar.gz"
  kubeconfig = <<-EOT
apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: ${data.aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${data.aws_eks_cluster.cluster.certificate_authority.0.data}
  name: this

contexts:
- context:
    cluster: this
    user: this
  name: this

current-context: this

users:
- name: this
  user:
    token: ${data.aws_eks_cluster_auth.cluster.token}
EOT
}
