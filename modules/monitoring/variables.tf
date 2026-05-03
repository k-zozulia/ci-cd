variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the EKS cluster."
  type        = string
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace where Prometheus and Grafana will be deployed."
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_password" {
  description = "Admin password for the Grafana UI."
  type        = string
  default     = "admin123"
  sensitive   = true
}
