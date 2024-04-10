resource "random_password" "pgvector_password" {
  length           = 20
  special          = true
  override_special = "_%@"
}