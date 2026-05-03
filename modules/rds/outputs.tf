# --------------------------------------------------
# Shared outputs (available in both modes)
# --------------------------------------------------
output "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}

output "security_group_id" {
  description = "ID of the database security group."
  value       = aws_security_group.this.id
}

output "parameter_group_name" {
  description = "Name of the DB parameter group."
  value       = aws_db_parameter_group.this.name
}

# --------------------------------------------------
# Standard RDS outputs (use_aurora = false)
# --------------------------------------------------
output "rds_instance_id" {
  description = "ID of the RDS instance. Available only when use_aurora = false."
  value       = var.use_aurora ? null : aws_db_instance.this[0].id
}

output "rds_instance_endpoint" {
  description = "Connection endpoint of the RDS instance. Available only when use_aurora = false."
  value       = var.use_aurora ? null : aws_db_instance.this[0].endpoint
}

output "rds_instance_address" {
  description = "Hostname of the RDS instance. Available only when use_aurora = false."
  value       = var.use_aurora ? null : aws_db_instance.this[0].address
}

# --------------------------------------------------
# Aurora outputs (use_aurora = true)
# --------------------------------------------------
output "aurora_cluster_id" {
  description = "ID of the Aurora cluster. Available only when use_aurora = true."
  value       = var.use_aurora ? aws_rds_cluster.this[0].id : null
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster. Available only when use_aurora = true."
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster. Available only when use_aurora = true."
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}

output "aurora_writer_instance_id" {
  description = "ID of the Aurora writer instance. Available only when use_aurora = true."
  value       = var.use_aurora ? aws_rds_cluster_instance.writer[0].id : null
}

# --------------------------------------------------
# Universal endpoint (works in both modes)
# --------------------------------------------------
output "db_endpoint" {
  description = "Primary connection endpoint. Returns Aurora writer endpoint or RDS instance endpoint depending on use_aurora."
  value = var.use_aurora ? (
    aws_rds_cluster.this[0].endpoint
  ) : (
    aws_db_instance.this[0].endpoint
  )
}
