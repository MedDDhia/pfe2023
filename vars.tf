variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "us-east-1"
}


variable "cluster_name" {
  default= "shared-eks-1"
}

variable "app_name" {
  default = "automation"
  description = "Name of the ArgoCD application"
}

variable "namespace" {
  default = "argocd"
  description = "namespace of the argocd"
}

variable "repo_url" {
  default= "https://gitlab.com/internship-course/monitoring.git"
  description = "URL of the Git repository for the application"
}


variable "targetRevision" {
  default = "addons"
  description = "targer revision of the application"
}
variable "releaseName" {
  default = "dhia"
  description = "release name of the application"
}

variable "repo_path" {
  default = "apps"
  description = "this values contains the path of the applications"
  
}
