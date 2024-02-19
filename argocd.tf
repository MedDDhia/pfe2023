data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "gitlab-creds"
}

locals {
  credentials = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

resource "helm_release" "argocd"{
name = "argocd"
repository = "https://argoproj.github.io/argo-helm"
chart = "argo-cd"
namespace = "argocd"
create_namespace = true
version = "5.46.4"
values = [file("values/argocd.yaml")]
}



resource "kubectl_manifest" "application" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.app_name}
  namespace: ${var.namespace}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    path: ${var.repo_path}
    repoURL: ${var.repo_url}
    targetRevision: ${var.targetRevision}
    
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - Validate=true
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true

YAML

depends_on = [ helm_release.argocd ]
}


resource "kubectl_manifest" "secret" {
    yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: argocd-met
  namespace: ${var.namespace}
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: https://gitlab.com/internship-course/monitoring.git
  name: random
  username: ${sensitive(local.credentials.username)}
  password: ${sensitive(local.credentials.password)}
  insecure: "false"
  enableLfs: "true"
  
YAML

depends_on = [ helm_release.argocd ]
}


