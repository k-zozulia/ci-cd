# --------------------------------------------------
# Aurora Cluster
# Created only when use_aurora = true
# --------------------------------------------------
resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.identifier
  engine             = var.engine
  engine_version     = var.engine_version

  database_name   = var.db_name
  master_username = var.db_username
  master_password = var.db_password
  port            = var.db_port

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name

  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period

  tags = merge(var.tags, {
    Name = var.identifier
  })
}

# --------------------------------------------------
# Aurora Cluster Parameter Group
# Separate from aws_db_parameter_group; applies
# cluster-level settings for Aurora.
# --------------------------------------------------
resource "aws_rds_cluster_parameter_group" "this" {
  count = var.use_aurora ? 1 : 0

  name   = "${var.identifier}-cluster-pg"
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
    Name = "${var.identifier}-cluster-pg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --------------------------------------------------
# Aurora Writer Instance
# Primary read/write node of the Aurora cluster.
# --------------------------------------------------
resource "aws_rds_cluster_instance" "writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.identifier}-writer"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this[0].engine
  engine_version     = aws_rds_cluster.this[0].engine_version

  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.this.name

  tags = merge(var.tags, {
    Name = "${var.identifier}-writer"
    Role = "writer"
  })
}
