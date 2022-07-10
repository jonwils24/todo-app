# TF Release v0.0.3

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  name = "jw-todos-app"
}

module "static_site" {
  source      = "./modules/static_site"
  bucket_name = local.name
}

module "todos_api" {
  source = "./modules/api"
  name   = local.name
}
