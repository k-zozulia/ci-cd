output "jenkins_namespace" {
  description = "Namespace where Jenkins is deployed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_name" {
  description = "Jenkins service name"
  value       = helm_release.jenkins.name
}