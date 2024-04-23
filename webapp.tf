module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.0"

  cluster_name = "librechat-cluster"

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

  cluster_settings = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  tags = {
    Environment = "Development"
    Project     = "LibreChat"
  }
}

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.1"

  name        = "librechat_service"
  cluster_arn = module.ecs.cluster_arn

  cpu    = 1024
  memory = 4096

  container_definitions = {

    librechat-web-app = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "ghcr.io/danny-avila/librechat-dev-api:latest"
      memory_reservation = 50
      port_mappings = [
        {
          name          = "http"
          containerPort = 3080
          protocol      = "tcp"
        }
      ]
      dependencies = [{
        condition     = "SUCCESS"
        containerName = "rag_api"
      }]
      environment = [
        {
          name  = "HOST"
          value = "0.0.0.0"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name = "MONGO_URI"
          # If using documentdb, use this value
          # value = "${aws_docdb_cluster.mongodb_cluster.endpoint}:27017/LibreChat"
          # If using ec2, use this value
          value = "${aws_instance.mongodb.private_ip}:27017/LibreChat"
        },
        {
          name  = "MEILI_HOST"
          value = aws_instance.meilisearch.private_ip
        },
        {
          name  = "RAG_PORT"
          value = "8000"
        },
        {
          name  = "RAG_API_URL"
          value = "http://localhost:8000"
        }
      ]

      # TODO: Fix this stuff
      # environment_files = [
      #   {
      #     type  = "s3"
      #     value = "${aws_s3_bucket.env_bucket.arn}"
      #   }
      # ]
      # mount_points = [
      #   {
      #     container_path = "/images"
      #     source_volume  = "app_images"
      #   },
      #   {
      #     container_path = "/logs"
      #     source_volume  = "app_logs"
      #   }
      # ]

      # Not needed on a vpc
      # extra_hosts = [
      #   {
      #     hostname  = "host.docker.internal"
      #     ipAddress = "host-gateway"
      #   }
      # ]
      log_configuration = {
        log_driver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${module.ecs.cluster_name}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "librechat-web-app"
        }
      }
    }

    rag_api = {
      cpu       = 512
      memory    = 1024
      essential = false
      image     = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest"
      environment = [
        {
          name  = "DB_HOST"
          value = "vectordb"
        },
        {
          name  = "RAG_PORT"
          value = "8000"
        }
      ]

      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/${module.ecs.cluster_name}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "rag-api"
        }
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

  volume = {
    name      = "app_images"
    host_path = "/app/client/public/images"
  }

  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.ecs_target_group.arn
      container_name   = "librechat-web-app"
      container_port   = 3080
    }
  }

  subnet_ids         = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
  security_group_ids = [aws_security_group.ecs_sg.id]
}

resource "aws_cloudwatch_log_stream" "webapp-stream" {
  name           = "librechat-web-app"
  log_group_name = module.ecs.cloudwatch_log_group_name
}

resource "aws_cloudwatch_log_stream" "rag-api-stream" {
  name           = "rag-api"
  log_group_name = module.ecs.cloudwatch_log_group_name
}

resource "aws_s3_bucket" "env_bucket" {
  bucket = "librechat-${random_pet.bucket_suffix.id}"
}

resource "aws_s3_bucket_policy" "env_bucket_policy" {
  bucket = aws_s3_bucket.env_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Meilisearch official AMI
resource "aws_instance" "meilisearch" {
  ami                    = "ami-0e8b58789f72d4790"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.meilisearch_sg.id]
  subnet_id              = aws_subnet.subnet_1.id
  tags = {
    Name = "meilisearch"
  }
}

# MongoDB EC2 much cheaper than DocDB
resource "aws_instance" "mongodb" {
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  subnet_id              = aws_subnet.subnet_1.id
  user_data              = <<-EOF
      #!/bin/bash
      # Update the package list
      sudo apt-get update
      # Install MongoDB
      sudo apt-get install -y mongodb

      # Enable MongoDB to start on boot
      sudo systemctl enable mongodb
      # Get the public DNS name of the instance
      PUBLIC_DNS_NAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

      # Replace the bindIp line in the /etc/mongod.conf file
      sed -i "s/bindIp: 127.0.0.1/bindIp: $PUBLIC_DNS_NAME/g" /etc/mongod.conf

      # Restart the MongoDB service
      sudo service mongod restart

      # Install AWS CloudWatch Logs agent
      curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
      sudo python3 awslogs-agent-setup.py --region us-west-1

      # Configure AWS CloudWatch Logs agent
      sudo tee /var/awslogs/etc/awslogs.conf <<-CONFIG
      [/var/log/mongodb/mongodb.log]
      datetime_format = %Y-%m-%d %H:%M:%S
      file = /var/log/mongodb/mongodb.log
      buffer_duration = 5000
      log_stream_name = {instance_id}
      initial_position = start_of_file
      log_group_name = mongodb-log-group
      CONFIG

      # Start the AWS CloudWatch Logs agent
      sudo service awslogs start
      EOF
  
  tags = {
    Name = "mongodb"
  }
}

resource "aws_cloudwatch_log_group" "mongodb_log_group" {
  name = "mongodb-log-group"
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}
