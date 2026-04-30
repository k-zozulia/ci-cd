resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.3"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  timeout = 600

  depends_on = [kubernetes_namespace.argocd]
}

# Helm release для Argo CD Applications
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "applications[0].repoURL"
    value = var.github_repo
  }

  set {
    name  = "repositories[0].url"
    value = var.github_repo
  }

  set {
    name  = "repositories[0].password"
    value = var.github_token
  }

  depends_on = [helm_release.argocd]
}