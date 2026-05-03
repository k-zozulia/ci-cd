variable "use_aurora" {
  description = "If true, creates an Aurora Cluster. If false, creates a standard RDS instance."
  type        = bool
  default     = false
}

variable "identifier" {
  description = "Unique identifier for the RDS instance or Aurora cluster."
  type        = string
}

variable "engine" {
  description = "Database engine: 'mysql', 'postgres', 'aurora-mysql', or 'aurora-postgresql'."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Version of the database engine."
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "Instance class for the DB (e.g. db.t3.medium, db.r6g.large)."
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB. Applies to standard RDS only, not Aurora."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database to create."
  type        = string
  default     = "mydb"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the database."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment. Applies to standard RDS only."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where RDS will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB Subnet Group. At least 2 subnets in different AZs are required."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "db_port" {
  description = "Port on which the database accepts connections. Use 5432 for PostgreSQL and 3306 for MySQL."
  type        = number
  default     = 5432
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups. Set to 0 to disable backups."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection on the database resource."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to apply to all resources created by this module."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
