# Create and manage AWS IAM users and roles with Terraform

## Introduction
what are we doing in this article

- Outline basic project and goals – this should be at least a bit realistic but very simple. E.g. allowing a user to download files from an S3 bucket or similar.

## Prerequisites
- An AWS account, free tier or greater. If you don't have one, sign up [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html?.nc2=h_ct&src=header_signup)

budget
cost notification



Terraform installed, AWS account up and running, IAM keys suitable for using with the terraform

## What do we use AWS for?
Users want to use Terraform to create and manage IAM users and roles on AWS.
This is both for convenience (avoid repetitive UI actions) and compliance/governance (if you Terraform scripts are in git, you can prove who had access to what resource when, and that they are correctly offboarded from resources when needed)

## Run AWS CLI version 2 in Docker

We use the [AWS CLI in Docker](https://hub.docker.com/r/amazon/aws-cli).
```bash
docker run --rm -it amazon/aws-cli:2.13.30 --version # delete the container when finished the command.
```

### Stay in AWS free
AWS [DynamoDB](https://aws.amazon.com/dynamodb) is always free to store 25GB. Completing this tutorial will cost you no AWS fees.

### Create a database
Create a DynamoDb table called `Person` with partition key `Id`, a string, and sort key `Email`, a string. Use the default table settings.

![Create a DynamoDB table](./assets/dynamodb.jpg)

### Create a new user
In the **IAM service** → **Users**, create a new user called `DbUser`, with no console permissions.

### Create a role


- store files
- create and manage users to access the files
- create and manage roles to manage user access to the files
  - what is IAM
  - Create a role / group / both ?
  - Assign a role to a user

### Use AWS manually to manage files and users

## What do we use Terraform for?
- what is terraform
  - give examples
- how do we use it with AWS
    - Connecting AWS and Terraform

We use the [Terraform CLI in Docker](https://hub.docker.com/r/hashicorp/terraform).
```bash
docker pull hashicorp/terraform:1.6
```

    - How do I create an IAM User with Terraform
    - How do I create an IAM Role with Terraform
    - How do I manage existing IAM Users and Roles (e.g. those created initially using the AWS Web Console) with Terraform
    - (Can either also set up a resource like an S3 bucket via Terraform or manually via the UI to use as an example of what the role allows the user to do)
  - Make changes to the existing user (e.g. revoke access to the S3 bucket again)


## What is Abbey, and how does it make this easier?

- What Abbey offers on top of this either in terms of
- Extra features (more control)
- Simpler / easier?
- More compliance?
- Single interface to manage access to all resources, not just AWS (e.g. Snowflake).