# Create and manage AWS IAM users and roles with Terraform

## Introduction
what are we doing in this article

- Outline basic project and goals – this should be at least a bit realistic but very simple. E.g. allowing a user to download files from an S3 bucket or similar.

## Prerequisites

Terraform installed, AWS account up and running, IAM keys suitable for using with the terraform

## What do we use AWS for?
Users want to use Terraform to create and manage IAM users and roles on AWS.
This is both for convenience (avoid repetitive UI actions) and compliance/governance (if you Terraform scripts are in git, you can prove who had access to what resource when, and that they are correctly offboarded from resources when needed)

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