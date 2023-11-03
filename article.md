# Create and manage AWS IAM users and roles with Terraform

- [Create and manage AWS IAM users and roles with Terraform](#create-and-manage-aws-iam-users-and-roles-with-terraform)
  - [Introduction](#introduction)
    - [A few definitions](#a-few-definitions)
  - [Prerequisites](#prerequisites)
  - [What do we use AWS for?](#what-do-we-use-aws-for)
  - [Run AWS CLI version 2 in Docker](#run-aws-cli-version-2-in-docker)
    - [Stay in AWS free](#stay-in-aws-free)
    - [Create a database](#create-a-database)
    - [Create a new user](#create-a-new-user)
    - [Create a role](#create-a-role)
    - [Use AWS manually to manage files and users](#use-aws-manually-to-manage-files-and-users)
  - [What do we use Terraform for?](#what-do-we-use-terraform-for)
  - [What is Abbey, and how does it make this easier?](#what-is-abbey-and-how-does-it-make-this-easier)


## Introduction

This article explains how to use Terraform to manage user access to a database in AWS. First, it explains how to configure users and roles in IAM to manage access. Then it explains how to use Terraform to do the same thing, with benefits. Finally, the article gives an overview of how using Abbey can make the process simpler.

### A few definitions

Below are a few AWS access management concepts that are used throughout this tutorial.

Concept | Explanation
--- | ---
AWS account | An AWS client's organization, consisting of team members, applications, databases, and billing.
AWS user | An identity, that can be a person or application. It has passwords, access keys, and permissions.
AWS group | A collection of users, that can be used to apply permissions to multiple users at once.
AWS IAM | Identity and Access Management — the service that manages all users and permissions in your AWS account.
AWS [CloudFormation](https://aws.amazon.com/cloudformation/) | A configuration service provided by AWS, that allows you to create and configure users and applications declaratively, in JSON or YAML files. Without using CloudFormation, you need to imperatively set up AWS components through the website (console), or by running commands through the AWS CLI in a terminal.
[Terraform](https://www.terraform.io/) | An application similar to CloudFormation, that allows declarative configuration. However, Terraform is not created by AWS. It is a level of abstraction above AWS. Terraform can be run on any server you have access to, and uses the same configuration files to manage access on [different cloud providers](https://registry.terraform.io/), including Azure, AWS, and Google Cloud.
[Abbey](https://www.abbey.io/) | A service that is a level of abstraction above Terraform. It is a web application where users can request access to cloud resources and administrators can approve them. Permissions are automatically adjusted in your connected Terraform GitHub account and configured on AWS.

Although AWS provides CloudFormation for configuration, we recommend Terraform in this article as it has a few benefits:
- It separates planning and execution of your configuration changes, allowing you to see what will happen before you run your change.
- If you ever want to include a cloud service other than AWS, Terraform can manage both with the same configuration files.
- It is more powerful, with a large open-source ecosystem, and arguably simpler configuration language.

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

Abbey is [free](https://www.abbey.io/pricing/) for teams of twenty people or fewer.

https://github.com/abbeylabs/abbey-starter-kit-aws-iam

- How do you stop using abbey without breaking terraform?
- Is abbey hosted locally or on their servers?
- What Abbey offers on top of this either in terms of
- Extra features (more control)
- Simpler / easier?
- More compliance?
- Single interface to manage access to all resources, not just AWS (e.g. Snowflake).