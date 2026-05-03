# --------------------------------------------------
# DB Subnet Group
# --------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

# --------------------------------------------------
# Security Group
# --------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for RDS ${var.identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound traffic on the database port"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-sg"
  })
}

# --------------------------------------------------
# Parameter Group family resolution
# Determines the correct family string based on
# engine type and whether Aurora is used.
# --------------------------------------------------
locals {
  pg_family = var.use_aurora ? (
    can(regex("mysql", var.engine)) ? "aurora-mysql8.0" : "aurora-postgresql15"
  ) : (
    can(regex("mysql", var.engine)) ? "mysql8.0" : "postgres15"
  )
}

# --------------------------------------------------
# DB Parameter Group
# Shared by both standard RDS and Aurora instances.
# Includes max_connections, log_statement, work_mem.
# --------------------------------------------------
resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-pg"
  family = local.pg_family

  # Maximum number of concurrent database connections
  parameter {
    name  = "max_connections"
    value = "200"
  }

  # Log DDL statements such as CREATE, ALTER, DROP (PostgreSQL only)
  dynamic "parameter" {
    for_each = can(regex("postgres", local.pg_family)) ? [1] : []
    content {
      name  = "log_statement"
      value = "ddl"
    }
  }

  # Memory used for internal sort operations, in kilobytes (PostgreSQL only)
  dynamic "parameter" {
    for_each = can(regex("postgres", local.pg_family)) ? [1] : []
    content {
      name  = "work_mem"
      value = "16384" # 16 MB
    }
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-pg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
