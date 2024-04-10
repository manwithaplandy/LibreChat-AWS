

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "ecs-integrated"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {
    librechat = {
      cpu    = 1024
      memory = 4096

      # Container definition(s)
      container_definitions = {

        librechat-web-app = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "ghcr.io/danny-avila/librechat-dev-api:latest"
          firelens_configuration = {
            type = "fluentbit"
          }
          memory_reservation = 50
          port_mappings = [
            {
              container_port = 3080
              host_port      = 3080
            }
          ]
          dependencies = [{
            condition = "SUCCESS"
            containerName = "rag_api"
          }]
          environment = [
            {
              name = "HOST"
              value = "0.0.0.0"
            },
            {
              name = "NODE_ENV"
              value = "production"
            },
            {
              name = "MONGO_URI"
              value = "${aws_docdb_cluster.mongodb_cluster.endpoint}"
            },
            {
              name = "MEILI_HOST"
              value = "${aws_instance.meilisearch.private_ip}"
            },
            {
              name = "RAG_PORT"
              value = "8000"
            }
          ]
          environment_files = [
            {
              type = "s3"
              value = "${aws_s3_bucket.env_bucket.arn}" 
            }
          ]
          mount_points = [
            {
              container_path = "./images"
              source_volume = "/app/client/public/images"
            },
            {
              container_path = "./logs"
              source_volume = "/app/logs"
            }
          ]
          extra_hosts = [
            {
              hostname = "host.docker.internal"
              ipAddress = "host-gateway"
            }
          ]
          log_configuration = {
            log_driver = "awslogs"

          }
        }

        rag_api = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest"
          environment = [
            {
              name = "DB_HOST"
              value = "vectordb"
            },
            {
              name = "RAG_PORT"
              value = "8000"
            }
          ]

          enable_cloudwatch_logging = true
          log_configuration = {
            logDriver = "awslogs"
          }
          memory_reservation = 50
        }

        # client = {

        # }
      }

      # service_connect_configuration = {
      #   namespace = "example"
      #   service = {
      #     client_alias = {
      #       port     = 80
      #       dns_name = "ecs-sample"
      #     }
      #     port_name      = "ecs-sample"
      #     discovery_name = "ecs-sample"
      #   }
      # }

      # load_balancer = {
      #   service = {
      #     target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:1234567890:targetgroup/bluegreentarget1/209a844cd01825a4"
      #     container_name   = "ecs-sample"
      #     container_port   = 80
      #   }
      # }

      subnet_ids = ["${aws_subnet.subnet_1.id}", "${aws_subnet.subnet_2.id}", "${aws_subnet.subnet_3.id}"]
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = "sg-12345678"
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = {
    Environment = "Development"
    Project     = "LibreChat"
  }
}

resource "aws_s3_bucket" "env_bucket" {
  bucket = "my-bucket-name"
}

resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.bucket
  acl    = "private"
}

resource "aws_db_instance" "pgvector_db" {
  engine               = "postgres"
  instance_class       = "db.t2.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  identifier           = "pgvector-db"
  username             = "admin"
  password             = random_password.pgvector_password.result
  publicly_accessible = false
  vpc_security_group_ids = ["${module.ecs.security_group_id}"]
  tags = {
    Name = "pgvector-db"
  }
}

resource "aws_docdb_cluster" "mongodb_cluster" {
  cluster_identifier      = "mongodb-cluster"
  engine                  = "docdb"
  master_username         = "admin"
  master_password         = random_password.mongodb_password.result
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = ["${module.ecs.security_group_id}"]
  tags = {
    Name = "mongodb-cluster"
  }
}

resource "aws_docdb_cluster_instance" "mongodb_instance" {
  identifier         = "mongodb-instance"
  cluster_identifier = aws_docdb_cluster.mongodb_cluster.id
  instance_class     = "db.r5.large"
  tags = {
    Name = "mongodb-instance"
  }
}

resource "aws_security_group_rule" "mongodb_ingress" {
  type                     = "ingress"
  security_group_id        = aws_docdb_cluster.mongodb_cluster.vpc_security_group_ids[0]
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = module.ecs.security_group_id
}

resource "aws_instance" "meilisearch" {
  ami           = "ami-0e8b58789f72d4790"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  tags = {
    Name = "meilisearch"
  }
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6..."
}


