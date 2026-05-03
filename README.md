# Module `rds`

A universal Terraform module for deploying a managed database on AWS.  
Supports both a **standard RDS instance** and an **Aurora Cluster** via a single `use_aurora` variable.

---

## What this module creates

In both modes the following resources are always created:
- `aws_db_subnet_group` — subnet group for the database
- `aws_security_group` — security group allowing access on the database port
- `aws_db_parameter_group` — parameter group with `max_connections`, `log_statement`, and `work_mem`

When `use_aurora = false`:
- `aws_db_instance` — a single RDS instance

When `use_aurora = true`:
- `aws_rds_cluster` — Aurora cluster
- `aws_rds_cluster_parameter_group` — cluster-level parameter group
- `aws_rds_cluster_instance` — writer instance

---

## Usage examples

### Standard RDS (PostgreSQL)

```hcl
module "rds" {
  source = "./modules/rds"

  use_aurora     = false
  identifier     = "my-postgres-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"

  db_name     = "mydb"
  db_username = "dbadmin"
  db_password = "SuperSecret123!"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  multi_az            = false
  allocated_storage   = 20
  skip_final_snapshot = true
}
```

### Aurora PostgreSQL Cluster

```hcl
module "rds" {
  source = "./modules/rds"

  use_aurora     = true
  identifier     = "my-aurora-cluster"
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_class = "db.r6g.large"

  db_name     = "mydb"
  db_username = "dbadmin"
  db_password = "SuperSecret123!"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  skip_final_snapshot = true
}
```

### Aurora MySQL Cluster

```hcl
module "rds" {
  source = "./modules/rds"

  use_aurora     = true
  identifier     = "my-aurora-mysql"
  engine         = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.04.0"
  instance_class = "db.t3.medium"
  db_port        = 3306

  db_name     = "mydb"
  db_username = "dbadmin"
  db_password = "SuperSecret123!"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

---

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `use_aurora` | `bool` | `false` | `true` creates an Aurora Cluster; `false` creates a standard RDS instance |
| `identifier` | `string` | — | Unique name used for all created resources |
| `engine` | `string` | `"postgres"` | DB engine: `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql` |
| `engine_version` | `string` | `"15.4"` | Version of the DB engine |
| `instance_class` | `string` | `"db.t3.medium"` | Instance class (affects CPU and RAM) |
| `allocated_storage` | `number` | `20` | Disk size in GB (standard RDS only) |
| `db_name` | `string` | `"mydb"` | Name of the initial database |
| `db_username` | `string` | `"dbadmin"` | Master username (sensitive) |
| `db_password` | `string` | — | Master password (sensitive) |
| `multi_az` | `bool` | `false` | Enable Multi-AZ deployment (standard RDS only) |
| `db_port` | `number` | `5432` | Database port (5432 for PostgreSQL, 3306 for MySQL) |
| `skip_final_snapshot` | `bool` | `true` | Skip final snapshot on deletion |
| `deletion_protection` | `bool` | `false` | Protect the database from accidental deletion |
| `backup_retention_period` | `number` | `7` | Number of days to retain automated backups |
| `vpc_id` | `string` | — | ID of the VPC where the database will be deployed |
| `subnet_ids` | `list(string)` | — | Subnet IDs for the DB Subnet Group (minimum 2 in different AZs) |
| `allowed_cidr_blocks` | `list(string)` | `["10.0.0.0/16"]` | CIDR blocks allowed to connect to the database |
| `tags` | `map(string)` | `{ManagedBy="Terraform"}` | Tags applied to all resources |

---

## Outputs

| Output | Description |
|--------|-------------|
| `db_endpoint` | Universal primary endpoint (works in both modes) |
| `rds_instance_endpoint` | RDS instance endpoint (`use_aurora = false` only) |
| `rds_instance_address` | RDS instance hostname (`use_aurora = false` only) |
| `aurora_cluster_endpoint` | Aurora writer endpoint (`use_aurora = true` only) |
| `aurora_reader_endpoint` | Aurora reader endpoint (`use_aurora = true` only) |
| `aurora_writer_instance_id` | Aurora writer instance ID (`use_aurora = true` only) |
| `security_group_id` | ID of the database security group |
| `db_subnet_group_name` | Name of the DB subnet group |
| `parameter_group_name` | Name of the DB parameter group |

---

## How to change the DB type, engine, or instance class

**Switch to MySQL:**
```hcl
engine         = "mysql"
engine_version = "8.0"
db_port        = 3306
```

**Use a larger instance class for production:**
```hcl
instance_class = "db.r6g.xlarge"
```

**Enable Multi-AZ (standard RDS only):**
```hcl
multi_az = true
```

**Enable deletion protection for production:**
```hcl
deletion_protection = true
skip_final_snapshot = false
```

---

## Integration with main.tf

```hcl
module "rds" {
  source = "./modules/rds"

  use_aurora     = false
  identifier     = "lesson-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"

  db_name     = "mydb"
  db_username = "myuser"
  db_password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "lesson-db"
  }
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}
```

> ⚠️ Remember to run `terraform destroy` after testing to avoid unexpected AWS charges.