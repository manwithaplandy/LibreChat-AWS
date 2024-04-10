resource "random_password" "pgvector_password" {
  length           = 20
  special          = true
  override_special = "_%@"
}

resource "random_password" "mongodb_password" {
  length           = 20
  special          = true
  override_special = "_%@"
}