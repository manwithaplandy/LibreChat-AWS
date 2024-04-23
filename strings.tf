resource "random_password" "pgvector_password" {
  length           = 20
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~" # allowed special characters by pgvector
}

resource "random_password" "mongodb_password" {
  length           = 20
  special          = true
  override_special = "/ _%@\""
}

resource "random_pet" "bucket_suffix" {
  length = 2
}