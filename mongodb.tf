# resource "aws_docdb_cluster" "mongodb_cluster" {
#   cluster_identifier      = "mongodb-cluster"
#   engine                  = "docdb"
#   master_username         = "admin"
#   master_password         = random_password.mongodb_password.result
#   backup_retention_period = 7
#   preferred_backup_window = "07:00-09:00"
#   vpc_security_group_ids  = ["${aws_security_group.ecs_sg.id}"]
#   engine_version = 5.0
#   tags = {
#     Name = "mongodb-cluster"
#   }
# }

# resource "aws_docdb_cluster_instance" "mongodb_instance" {
#   identifier         = "mongodb-instance"
#   cluster_identifier = aws_docdb_cluster.mongodb_cluster.id
#   instance_class     = "db.t3.medium"
#   tags = {
#     Name = "mongodb-instance"
#   }
# }