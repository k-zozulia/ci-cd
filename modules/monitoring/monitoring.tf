resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

# Prometheus + Grafana via kube-prometheus-stack Helm chart
resource "helm_release" "monitoring" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "58.2.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [file("${path.module}/values.yaml")]

  timeout = 600

  depends_on = [kubernetes_namespace.monitoring]
}
