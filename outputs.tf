output "webapp_url" {
    value = aws_lb.webapp.dns_name
}

output "database_endpoint" {
    value = aws_rds_instance.database.endpoint
}

output "bucket_name" {
    value = aws_s3_bucket.bucket.id
}