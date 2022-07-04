terraform {
  backend "s3" {
    encrypt = true
    bucket  = "jw-tf-state-bucket"
    region  = "us-east-1"
    key     = "todo_app/terraform.tfstate"
  }
}
