variable "helm_values" {
  default = null
}

variable "stage" {
  default = "prod"
}

variable "wait_for_resources" {
  default = true
}

variable "aws_eks_cluster_name" {
}
