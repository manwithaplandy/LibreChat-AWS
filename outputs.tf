output "webapp_url" {
    value = "http://${aws_lb.lb.dns_name}"
}