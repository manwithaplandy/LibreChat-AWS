

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
              value = "REPLACEME" # TODO: Get this value
            },
            {
              name = "MEILI_HOST"
              value = "REPLACEME" # TODO: Update with meili url
            },
            {
              name = "RAG_PORT"
              value = "REPLACEME" # TODO: create variable and update here
            }
          ]
          environment_files = [
            {
              type = "s3"
              value = "REPLACEME" # Put .env files in S3 and reference here
            }
          ]
          mount_points = [
            {
              container_path = "./images"
              source_volume = "REPLACEME"
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
              value = "REPLACEME" # TODO: Get RAG port
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

# TODO: S3 bucket for .env files

# TODO: RDS Postgres db for pgvector

# TODO: DocumentDB for MongoDB service

# TODO: Meilisearch EC2 on free tier