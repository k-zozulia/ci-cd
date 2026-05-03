output "monitoring_namespace" {
  description = "Namespace where Prometheus and Grafana are deployed."
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_service_name" {
  description = "Grafana service name inside the cluster."
  value       = "${helm_release.monitoring.name}-grafana"
}

output "prometheus_service_name" {
  description = "Prometheus service name inside the cluster."
  value       = "${helm_release.monitoring.name}-kube-prometheus-stack-prometheus"
}
