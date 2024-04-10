resource "aws_security_group" "ecs_sg" {
  name        = "ecs-security-group"
  description = "Security group for ECS services"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    description              = "Service port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "Allow inbound traffic for MongoDB"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  tags = {
    Name = "mongodb_sg"
  }
}

resource "aws_security_group" "pgvector_sg" {
  name        = "pgvector_sg"
  description = "Allow inbound traffic for pgvector"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_security_group" "meilisearch_sg" {
  name        = "meilisearch_sg"
  description = "Allow inbound traffic on port 7700 for meilisearch"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 7700
    to_port     = 7700
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}