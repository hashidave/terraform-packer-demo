#
#  a Postgres RDS Instance
#

# get info from Vault
#data "vault_generic_secret" "postgres-pw" {
#  path = "ssh/roles/RandomPassword"
#}

# Generate a random password for RDS (this will be handed off
# to Vault to create a connection & we won't need to see it again
resource "random_password" "pg-password" {
  length           = 16
  special          = true
  override_special = "!%"
}


resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "boundary-rds-demo-${var.environment}"
  subnet_ids = [aws_subnet.BoundaryRDS1.id, aws_subnet.BoundaryRDS2.id]

  tags = {
    Name = "Boundary RDS Demo ${var.environment}"
  }
}


resource "aws_db_parameter_group" "BoundaryRDS" {
  name   = "boundary-rds-${var.environment}"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}



resource "aws_db_instance" "db-instance" {
  identifier             = "boundary-rds-demo-${var.environment}"
  instance_class         = "db.t3.micro"
  db_name                = "test"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.3"
  username               = "dmradmin"
  password               = random_password.pg-password.result
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.BoundaryRDS.id]
  parameter_group_name   = aws_db_parameter_group.BoundaryRDS.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}




