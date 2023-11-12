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


# create database Person
# -----------------------------------

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


# create user carol
# -----------------------------------

resource "aws_iam_user" "carol" {
  name = "carol"
}

resource "aws_iam_access_key" "carol_key" {
  user = aws_iam_user.carol.name
}


# create dbreader role
# -----------------------------------

resource "aws_iam_role" "dbreader" {
  name = "dbreader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          "AWS": "arn:aws:iam::038824608327:root"
        },
        Condition: {  }
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "dbreader_dynamodb_readonly" {
  role       = aws_iam_role.dbreader.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}


# allow carol to assume dbreader
# -----------------------------------

data "aws_iam_policy_document" "carol_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [aws_iam_role.dbreader.arn]
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = ["2023-11-08T23:59:59Z"]
    }
  }
}

resource "aws_iam_policy" "carol_assume_dbreader_policy" {
  name   = "CarolAssumeDbReaderPolicy"
  policy = data.aws_iam_policy_document.carol_assume_role_policy.json
}

resource "aws_iam_user_policy_attachment" "carol_assume_role" {
  user       = aws_iam_user.carol.name
  policy_arn = aws_iam_policy.carol_assume_dbreader_policy.arn
}
