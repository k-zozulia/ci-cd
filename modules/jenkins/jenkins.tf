resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.1.5"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  set {
    name  = "controller.admin.password"
    value = var.jenkins_admin_password
  }

  timeout         = 900
  atomic          = false
  wait            = false

  depends_on = [kubernetes_namespace.jenkins]
}