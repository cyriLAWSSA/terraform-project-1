# VPC for DMS migration
resource "aws_vpc" "migration_vpc" {
  cidr_block = var.source_cidr

  tags = {
    Name = "migration-vpc"
  }
}

# Private subnets for DMS replication instance
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.migration_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.migration_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

# Subnet group for DMS replication instance
resource "aws_db_subnet_group" "migration_subnet_group" {
  name       = "migration-subnet-group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

# Security Group for DMS
resource "aws_security_group" "dms_sg" {
  name        = "dms-security-group"
  description = "Security group for DMS replication instance"
  vpc_id      = aws_vpc.migration_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.source_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "source_db" {
  identifier             = "source-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  username               = var.source_db_user
  password               = var.source_db_password
  db_subnet_group_name   = aws_db_subnet_group.migration_subnet_group.name
  vpc_security_group_ids = [aws_security_group.dms_sg.id]
}

resource "aws_db_instance" "target_db" {
  identifier             = "target-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  username               = var.target_db_user
  password               = var.target_db_password
  db_subnet_group_name   = aws_db_subnet_group.migration_subnet_group.name
  vpc_security_group_ids = [aws_security_group.dms_sg.id]
}
# DMS Replication Subnet Group
resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group"
  replication_subnet_group_description = "DMS Subnet Group"
  subnet_ids                           = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "dms-subnet-group"
  }
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "replication_instance" {
  allocated_storage           = 20
  replication_instance_class  = "dms.t3.medium"
  replication_instance_id     = "dms-replication-instance"
  vpc_security_group_ids      = [aws_security_group.dms_sg.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.id
  engine_version              = "3.5.2"
  publicly_accessible         = false
  apply_immediately           = true

  tags = {
    Name = "dms-replication-instance"
  }
}

# Source MySQL Endpoint
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source-endpoint"
  endpoint_type = "source"
  engine_name   = "mysql"
  username      = var.source_db_user
  password      = var.source_db_password
  server_name   = aws_db_instance.source_db.address
  port          = var.source_db_port
  database_name = var.source_db_name

  tags = {
    Name = "source-endpoint"
  }
}

# Target MySQL Endpoint
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target-endpoint"
  endpoint_type = "target"
  engine_name   = "mysql"
  username      = var.target_db_user
  password      = var.target_db_password
  server_name   = aws_db_instance.target_db.address
  port          = var.target_db_port
  database_name = var.target_db_name

  tags = {
    Name = "target-endpoint"
  }
}

# DMS Replication Task
resource "aws_dms_replication_task" "migration_task" {
  replication_task_id       = "migration-task"
  migration_type            = "full-load"
  replication_instance_arn  = aws_dms_replication_instance.replication_instance.replication_instance_arn
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  table_mappings            = file("table-mappings.json")
  replication_task_settings = file("task-settings.json")

  tags = {
    Name = "migration-task"
  }
}
