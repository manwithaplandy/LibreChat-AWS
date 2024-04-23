resource "aws_security_group" "ecs_sg" {
  name        = "ecs-security-group"
  description = "Security group for ECS services"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "ecs_sg"
  }
}

resource "aws_security_group_rule" "ecs_ingress_rule" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks = [ "0.0.0.0/0" ]

  description = "Service port"
}

resource "aws_security_group_rule" "ecs_egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks = [ "0.0.0.0/0" ]
}

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "Allow inbound traffic for MongoDB"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "mongodb_sg"
  }
}

resource "aws_security_group_rule" "mongo_ingress_rule" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.mongodb_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id

  description = "MongoDB port"
}

resource "aws_security_group" "pgvector_sg" {
  name        = "pgvector_sg"
  description = "Allow inbound traffic for pgvector"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "pgvector_sg"
  }
}

resource "aws_security_group_rule" "pgvector_ingress_rule" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.pgvector_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id

  description = "PostgreSQL port"
}

resource "aws_security_group" "meilisearch_sg" {
  name        = "meilisearch_sg"
  description = "Allow inbound traffic on port 7700 for meilisearch"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "meilisearch_sg"
  }
}

resource "aws_security_group_rule" "meili_ingress_rule" {
  type              = "ingress"
  from_port         = 7700
  to_port           = 7700
  protocol          = "tcp"
  security_group_id = aws_security_group.meilisearch_sg.id
  source_security_group_id = aws_security_group.ecs_sg.id

  description = "Service port"
}