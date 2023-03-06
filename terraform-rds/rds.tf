#
#  a Postgres RDS Instance
#
# Generate a random password for RDS (this will be handed off
# to Vault to create a connection & we won't need to see it again
resource "random_password" "pg-password" {
  length           = 16
  special          = true
  override_special = "+_-"
}


resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "${var.prefix}-${var.environment}"
  subnet_ids = [aws_subnet.BoundaryRDS1.id, aws_subnet.BoundaryRDS2.id]

  tags = {
    Name = "Boundary RDS Demo ${var.environment}"
  }
}


resource "aws_db_parameter_group" "BoundaryRDS" {
  name   = "${var.prefix}-${var.environment}"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}



resource "aws_db_instance" "db-instance" {
  count                  = var.db-count
  identifier             = "${var.prefix}-${var.environment}-${count.index}"
  instance_class         = "db.t3.micro"
  #db_name                = "test"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.5"
  username               = "dmradmin"
  password               = random_password.pg-password.result
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.BoundaryRDS.id]
  parameter_group_name   = aws_db_parameter_group.BoundaryRDS.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}




