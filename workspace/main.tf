terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" { region  = "eu-west-1" }

resource "aws_dynamodb_table" "person2" {
  name           = "Person2"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "Id"
  range_key      = "Email"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "Email"
    type = "S"
  }
}

resource "aws_iam_user" "carol" {
  name = "carol"
}

resource "aws_iam_access_key" "carol_key" {
  user = aws_iam_user.carol.name
}