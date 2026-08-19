resource "aws_db_instance" "postgredb" {
  allocated_storage     = 10
  max_allocated_storage = 20
  storage_type          = "gp2"
  db_name               = "mydb"
  engine                = "postgres"
  engine_version        = "15"
  instance_class        = "db.t3.micro"
  port                  = 5432
  publicly_accessible   = false
  db_subnet_group_name  = aws_db_subnet_group.mydb_subnet_group.name
  
  # Removed quotes from variable references
  username              = var.db_username
  password              = var.db_password

  parameter_group_name  = "default.postgres15"
  skip_final_snapshot   = true
  storage_encrypted     = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period    = 0
  auto_minor_version_upgrade = true
  deletion_protection        = false
  copy_tags_to_snapshot      = true
}

resource "aws_db_subnet_group" "mydb_subnet_group" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.rds_1.id, aws_subnet.rds_2.id]

  tags = {
    Name        = "mydb-subnet-group"
    environment = "production"
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.flask_vpc.id
  description = "Allow inbound access from VPC / application workloads only"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["10.0.0.0/16"] # Restricted to VPC CIDR
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_secretsmanager_secret" "db_secret" {
  name        = "production/rds/postgres-credentials"
  description = "Database credentials for RDS PostgreSQL instance"

  tags = {
    Environment = "production"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    host     = aws_db_instance.postgredb.address # Updated resource reference
    port     = aws_db_instance.postgredb.port    # Updated resource reference
    dbname   = aws_db_instance.postgredb.db_name # Updated resource reference
  })
}
