terraform {
  backend "s3" {
    bucket         = "karina-zozulia-tfstate"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}