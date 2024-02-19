provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}
#  provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }



terraform {
  required_providers {
   

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = ">= 2.6.0"
    # }
  }

  required_version = "~> 1.0"
}
