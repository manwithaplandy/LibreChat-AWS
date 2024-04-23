resource "aws_db_instance" "pgvector_db" {
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  identifier             = "pgvector-db"
  username               = "libreadmin"
  engine_version         = 16.2
  password               = random_password.pgvector_password.result
  publicly_accessible    = false
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.pgvector.name
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  tags = {
    Name = "pgvector-db"
  }
}
