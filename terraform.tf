provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "mystatebucket"
    key    = "myterraformapps/dev/terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "terraformstate"
  }
}