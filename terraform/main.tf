provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "static_site" {
  source      = "./modules/static_site"
  bucket_name = "tmp-todo-app"
}