output "argocd_namespace" {
  description = "Namespace where Argo CD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_service_name" {
  description = "Argo CD service name"
  value       = helm_release.argocd.name
}