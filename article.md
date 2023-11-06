# Create and manage AWS IAM users and roles with Terraform

- [Create and manage AWS IAM users and roles with Terraform](#create-and-manage-aws-iam-users-and-roles-with-terraform)
  - [Introduction](#introduction)
    - [A few definitions](#a-few-definitions)
  - [Prerequisites](#prerequisites)
  - [Configure database access in AWS IAM manually](#configure-database-access-in-aws-iam-manually)
    - [Create a database](#create-a-database)
    - [Create a user](#create-a-user)
    - [Create a role](#create-a-role)
    - [Read the database with the user using the role](#read-the-database-with-the-user-using-the-role)
    - [How to limit Bob's access to the table?](#how-to-limit-bobs-access-to-the-table)
    - [Run AWS CLI version 2 in Docker](#run-aws-cli-version-2-in-docker)
  - [Use Terraform to manage users](#use-terraform-to-manage-users)
  - [What is Abbey, and how does it make this easier?](#what-is-abbey-and-how-does-it-make-this-easier)


## Introduction

This article explains how to use Terraform to manage user access to a database in AWS. First, it explains how to configure users and roles in IAM to manage access. Then it explains how to use Terraform to do the same thing, with benefits. Finally, the article gives an overview of how using Abbey can make the process simpler.

### A few definitions

Below are AWS access management concepts that are used throughout this tutorial.

Concept | Explanation
--- | ---
AWS account | An AWS client's organization, consisting of team members, applications, databases, and billing.
AWS user | An identity, that can be a person or application. It has passwords, access keys, and permissions.
AWS group | A collection of users, that can be used to apply permissions to multiple users at once.
AWS role | An identity that is not any specific person or application, but rather one that a user can temporarily assume that grants a set of permissions.
AWS IAM | Identity and Access Management — the service that manages all users and permissions in your AWS account.
AWS [CloudFormation](https://aws.amazon.com/cloudformation/) | A configuration service provided by AWS, that allows you to create and configure users and applications declaratively, in JSON or YAML files. Without using CloudFormation, you need to imperatively set up AWS components through the website (console), or by running commands through the AWS CLI in a terminal.
[Terraform](https://www.terraform.io/) | An application similar to CloudFormation, that allows declarative configuration. However, Terraform is not created by AWS. It is a level of abstraction above AWS. Terraform can be run on any server you have access to, and uses the same configuration files to manage access on [different cloud providers](https://registry.terraform.io/), including Azure, AWS, and Google Cloud.
[Abbey](https://www.abbey.io/) | A service that is a level of abstraction above Terraform. It is a web application where users can request access to cloud resources and administrators can approve them. Permissions are automatically adjusted in your connected Terraform GitHub account and configured on AWS.

Although AWS provides CloudFormation for configuration, we recommend Terraform in this article as it has a few benefits:
- It separates planning and execution of your configuration changes, allowing you to see what will happen before you run your change.
- If you ever want to include a cloud service other than AWS, Terraform can manage both with the same configuration files.
- It is more powerful, with a large open-source ecosystem, and arguably simpler configuration language.

## Prerequisites

To follow this tutorial, you'll need:

- An AWS account. Free tier is fine. If you don't have an account, sign up [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html?.nc2=h_ct&src=header_signup)
- Docker, version 20 or greater. Docker allows you to run all commands in this tutorial, whether you're on Windows, Mac, or Linux. You're welcome to run commands directly on your machine instead, if you can handle differences that may occur.

> Terraform installed, AWS account up and running, IAM keys suitable for using with the terraform

## Configure database access in AWS IAM manually

In this section we'll create a [DynamoDB](https://aws.amazon.com/dynamodb) table, a user that wants to access it, and a role that the user can assume to access the table. Requiring the user to assume a role to access the table allows administrators to automatically revoke permissions from the user after a duration.

AWS DynamoDB is always free to store 25 GB. Completing this tutorial will cost you no AWS fees.

### Create a database

First, we create a database table:

- Browse to DynamoDB in the AWS web console.
- Create a DynamoDb table called `Person` with partition key string `Id` and sort key string `Email`. Use the default table settings.
  ![Create a DynamoDB table](./assets/dynamodb.jpg)
- Wait for AWS to create the table.
- Add a row to the table:
  - Click the table name.
  - Click "Explore table items".
  - Click "Create item".
  - Enter "Id" `1` and "Email" `alice@example.com`.
  - Click "Create item".
    ![Add a row](./assets/addItem.jpg)

### Create a user

Second, we create a user, who has no permissions by default, and will request access to read the value from the table:

- Browse to "IAM".
- Click "Users".
- Click "Create user".
- Enter name `bob`.
- Enable "Provide user access to the AWS Management Console".
- Select "I want to create an IAM user".
- Select "Custom password".
- Enter `P4ssword_`.
- Disable "Users must create a new password at next sign-in".
  ![Create user](./assets/createUser.jpg)
- Click "Next"
- Click "Create user"
- Click "Return to users list".

Now we need to give bob an access key so that he can use the CLI:

- Click "bob".
- Click "Create access key".
- Click "Command line interface".
- Enable "I understand the above recommendation and want to proceed to create an access key."
- Click "Next".
- Click "Create access key".
- Save both the access key and secret access key to a file to use later.
- Click "Done".

### Create a role

Finally, we create a role with permissions to read from the Person table

- Browse to "IAM".
- Click "Roles".
- Click "Create role".
- Select "AWS Account".
- Select "This account".
- Click "Next".
- Select "AmazonDynamoDBReadOnlyAccess".
- Click "Next".
- Under "Role name", enter `reader`.
- Click "Create role".

Now our example setup is complete and ready to test.

### Read the database with the user using the role

Bob wants the latest email addresses for all customers and so wants to access the Person table. He emails an AWS administrator at his company and asks for access.

The administrator then logs in to the console and does the following:

- Browse to "Users".
- Click "bob".
- In the "Permissions" tab, click "Add permissions" — "Create inline policy".
- Select "JSON".
- Copy and paste the policy below, replacing `<ACCOUNT-ID>` with your account number (found under your name at the very top right of the window).
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::<ACCOUNT-ID>:role/reader"
      }
    ]
  }
  ```
- Click "Next".
- Enter the name `bobreader`.
- Click "Create policy".

The administrator then replies to Bob's email, saying that he now has permissions to read the database.

Bob logs in to the AWS website, entering the company's account identifier, his name `bob`, and the password `P4ssword_`. He does the following:

- Select the region where the DynamoDB table is kept.
- Searches for the `DynamoDB` service.
- Clicks "Tables" and is told "Your role does not have permissions to view the list of tables.".
- Under your name at the top right of the screen, click "Switch role".
- Click "Switch role".
- Enter your account identifer in "Account".
- Enter `reader` in "Role".
- Enter anything in "Display Name".
- Click "Switch role".

Bob is returned to the tables screen, can click the Person table, click "Explore table items", and finally see Alice's email address.

![See the DynamoDB table](./assets/seeTable.jpg)

When he's done he can click "Switch back", under his username at the top right.

### How to limit Bob's access to the table?

If Bob doesn't need permanent access to the table, the administrator will want to remove Bob's permissions once he has read the data he needs. There are various ways of doing this:

- Set a calendar reminder to manually log in and delete `bobreader`, possibly after emailing Bob to check that he's done. This has a lot of room for human error.
- Create a custom script using AWS Lambda, CloudTrail, and CloudWatch, that triggers when Bob assumes the `reader` role and deletes `bobreader`. This is too much work, since user access is a common request.
- Set the date the policy ends. Bob will be able to assume the role as many times as he wants before this time. This is the most secure and simple way of assigning temporary access. To do this, you can add a date a few days in the future to `bobreader`:
  ```json
  "Condition": {
    "DateLessThan": {"aws:CurrentTime": "2023-11-06T23:59:59Z"}
  }
  ```

### Run AWS CLI version 2 in Docker

TODO - delete this, pointless given we have console and terraform and abbey.
We use the [AWS CLI in Docker](https://hub.docker.com/r/amazon/aws-cli).
```bash
docker run --rm -it amazon/aws-cli:2.13.30 --version # delete the container when finished the command.
```

## Use Terraform to manage users
- what is terraform
  - give examples
- how do we use it with AWS
    - Connecting AWS and Terraform

> Users want to use Terraform to create and manage IAM users and roles on AWS.
This is both for convenience (avoid repetitive UI actions) and compliance/governance (if you Terraform scripts are in git, you can prove who had access to what resource when, and that they are correctly offboarded from resources when needed)


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