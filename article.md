# Create and manage AWS IAM users and roles with Terraform

- [Create and manage AWS IAM users and roles with Terraform](#create-and-manage-aws-iam-users-and-roles-with-terraform)
  - [Introduction](#introduction)
    - [A few definitions](#a-few-definitions)
  - [Prerequisites](#prerequisites)
  - [Configure database access in AWS IAM manually](#configure-database-access-in-aws-iam-manually)
    - [Create a database](#create-a-database)
    - [Create a user](#create-a-user)
    - [Create a role](#create-a-role)
    - [Request access to the database](#request-access-to-the-database)
    - [Read the database with the user using the role](#read-the-database-with-the-user-using-the-role)
    - [How to limit Bob's access to the table?](#how-to-limit-bobs-access-to-the-table)
  - [Use Terraform to manage users](#use-terraform-to-manage-users)
    - [What is Terraform?](#what-is-terraform)
    - [Create an administrator in IAM](#create-an-administrator-in-iam)
    - [Install Terraform](#install-terraform)
    - [Set AWS credentials](#set-aws-credentials)
    - [Create a database](#create-a-database-1)
    - [Add a row to the table](#add-a-row-to-the-table)
    - [Create a user](#create-a-user-1)
    - [Create a role](#create-a-role-1)
    - [Request access to the database](#request-access-to-the-database-1)
    - [Read the database with the user using the role in the CLI](#read-the-database-with-the-user-using-the-role-in-the-cli)
  - [Advantages and disadvantages of Terraform](#advantages-and-disadvantages-of-terraform)
  - [What is Abbey, and how does it make this easier?](#what-is-abbey-and-how-does-it-make-this-easier)
    - [Install Abbey](#install-abbey)
    - [Make an access request with Abbey](#make-an-access-request-with-abbey)
    - [Read the database with the user using the group in the CLI](#read-the-database-with-the-user-using-the-group-in-the-cli)
    - [Revoke permissions](#revoke-permissions)
  - [Delete your temporary administrator](#delete-your-temporary-administrator)
    - [How exactly does Abbey work?](#how-exactly-does-abbey-work)
    - [What are the benefits of Abbey over using Terraform alone?](#what-are-the-benefits-of-abbey-over-using-terraform-alone)
    - [What are the disadvantages of Abbey?](#what-are-the-disadvantages-of-abbey)
    - [What are the alternatives to Abbey for access governance?](#what-are-the-alternatives-to-abbey-for-access-governance)
  - [Questions for Abbey](#questions-for-abbey)
  - [Problems with Abbey](#problems-with-abbey)
  - [Todo](#todo)


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
- It is more powerful, with a large ecosystem, and arguably simpler configuration language.

Note that versions of Terraform after 1.5 are no longer open source. The company changed their license in August 2023. You may soon want to switch to [OpenTofu](https://opentofu.org/), an open source form of Terraform that is currently working towards a stable release. Currently, OpenTofu is an exact substitute for Terraform, though they will diverge in syntax and features over time.

## Prerequisites

To follow this tutorial, you'll need:

- An AWS account. Free tier is fine. If you don't have an account, sign up [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html?.nc2=h_ct&src=header_signup).
- Docker, version 20 or greater. Docker allows you to run all commands in this tutorial, whether you're on Windows, Mac, or Linux. You're welcome to run commands directly on your machine instead, if you can handle differences that may occur.
- Git and a GitHub account.

> Terraform installed, AWS account up and running, IAM keys suitable for using with the terraform

## Configure database access in AWS IAM manually

In this section we'll create a [DynamoDB](https://aws.amazon.com/dynamodb) table, a user that wants to access it, and a role that the user can assume to access the table. AWS DynamoDB is always free to store 25 GB. Completing this tutorial will cost you no AWS fees.

Requiring the user to assume a role to access the table offers a few advantages over giving a user direct access to a resource:
- It limits access to the least privilege. Assuming the role will grant a user the permissions of that role, but remove all their other permissions.
- Credentials are safer, being temporary for a role. A user's access keys are permanent.
- Roles are centrally managed (you need to manage fewer roles than individual permissions for each user) and are thus more easily maintained and audited.

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

Finally, we create a role with permissions to read from the Person table:

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

### Request access to the database

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

### Read the database with the user using the role

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

## Use Terraform to manage users

In this section, we are going to repeat what was done in the previous section on AWS, but using Terraform instead. We will create a user called Carol and a role she can assume to read the DynamoDB table.

### What is Terraform?

Terraform is an open-source infrastructure as code (IaC) application that allows you to configure cloud infrastructure using configuration files. It is common to store these files in version control, like GitHub, so that configuration and access control can be collaborative, versioned, approved, and audited.

### Create an administrator in IAM

If you completed the earlier section and have the user Bob, please go to his user in the AWS console and add the new permission `AdministratorAccess`. Since you noted his access key you can use it in the AWS CLI, now that Bob is an administrator. Also browse to your DynamoDB Person table and delete it, as we will recreate it with Terraform.

If you didn't complete the earlier section, please create a new AWS user with the `AdministratorAccess` permission and create an access key for him.

### Install Terraform

We need a temporary place to work on files in this tutorial. Make any folder on your computer, like `temp`, and open a terminal inside it.

You're welcome to install AWS and Terraform manually on your machine, following the instructions on their websites, but a faster way is just to use Docker. Create a file called `Dockerfile` with the following content:

```dockerfile
FROM alpine:3.18.4

WORKDIR /workspace

RUN apk add   aws-cli   terraform
```

Build the container and start it:

```bash
docker build -t cloudbox_image .
docker run -it --volume .:/workspace --name cloudbox cloudbox_image
```

You are now inside the Docker container and able to use AWS and Terraform:

```bash
aws --version
terraform -v
```

If you exit the container and wish to start it again later, run:

```bash
docker start -ai cloudbox
```

The `--volume .:/workspace` parameter shares your current folder with the container, so both your physical machine and Docker can read and write the same files.

### Set AWS credentials

In the Docker terminal, set your administrator access key:

```bash
aws configure
# enter your user access key
# enter your user secret key
```

To test that your credentials are correct, you can run:

```bash
aws s3 ls
```

### Create a database

Next, we are going to start on a Terraform configuration file to provision our AWS infrastructure.

Create a file called `main.tf` in your shared workspace folder. Add the content below.

```terraform
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

resource "aws_dynamodb_table" "person" {
  name           = "Person
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
```

This infrastructure specification does only one thing — create a DynamoDB table called Person in the AWS Ireland region. Note that the AWS table name `Person` is separate from the Terraform resource name `person`. The latter can be whatever you want, and is used to refer to this resource anywhere in the Terraform configuration file.

Although AWS CLI is installed, Terraform still has to download its provider, since we used AWS in the configuration file. Run this command in the Docker terminal:

```bash
terraform init
```

The output will be:

```bash
/workspace # terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.16"...
- Installing hashicorp/aws v4.67.0...
- Installed hashicorp/aws v4.67.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Terraform downloaded large files to `.terraform`. Remember to exclude them from version control if you use `.gitignore`.

To check that your configuration file syntax is correct, run:

```bash
terraform validate

# Success! The configuration is valid.
```

Now let's create the database. Run:

```bash
terraform apply
# type yes and push enter
```

The output should be:

```bash
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_dynamodb_table.person will be created
  + resource "aws_dynamodb_table" "person {
      + arn              = (known after apply)
      + billing_mode     = "PROVISIONED"
      + hash_key         = "Id"
      + id               = (known after apply)
      + name             = "Person"
      + range_key        = "Email"
      + read_capacity    = 1
      + stream_arn       = (known after apply)
      + stream_label     = (known after apply)
      + stream_view_type = (known after apply)
      + tags_all         = (known after apply)
      + write_capacity   = 1

      + attribute {
          + name = "Email"
          + type = "S"
        }
      + attribute {
          + name = "Id"
          + type = "S"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_dynamodb_table.person: Creating...
aws_dynamodb_table.person: Creation complete after 10s [id=Person]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

If any resource, like another database table, exists in AWS but was not created by Terraform, Terraform will not manage it. Terraform does not modify resources that it did not create and are not in the state file. You can use the [import](https://developer.hashicorp.com/terraform/language/import) command to include existing AWS infrastructure in your Terraform configuration.

Note that Terraform created the file `terraform.tfstate`, to represent and track your AWS configuration. This file is essential to Terraform and must be safely kept and backed up, but also contains secrets and so should not be stored in Git. Include `terraform.tfstate*` in your `.gitignore` file. Managing your Terraform state is a complicated topic. This [article](https://spacelift.io/blog/terraform-state) is a good starting point. Secrets can be stored in AWS Parameter Store (free) or Secrets Manager (paid and more powerful).

### Add a row to the table

To check that the table exists, let's add a row:

```bash
aws dynamodb put-item \
    --table-name Person \
    --item '{
        "Id": {"S": "1"},
        "Email": {"S": "alice@example.com"}
    }'
```

If you browse to the database in the AWS console and "Explore table items", you can now see the new row.

### Create a user

Add the following code to `main.tf`.

```terraform
resource "aws_iam_user" "carol" {
  name = "carol"
}

resource "aws_iam_access_key" "carol_key" {
  user = aws_iam_user.carol.name
}
```

Run `terraform apply`.

The output is:

```bash
/workspace # terraform apply
aws_dynamodb_table.person2: Refreshing state... [id=Person2]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_access_key.carol_key will be created
  + resource "aws_iam_access_key" "carol_key" {
      + create_date                    = (known after apply)
      + encrypted_secret               = (known after apply)
      + encrypted_ses_smtp_password_v4 = (known after apply)
      + id                             = (known after apply)
      + key_fingerprint                = (known after apply)
      + secret                         = (sensitive value)
      + ses_smtp_password_v4           = (sensitive value)
      + status                         = "Active"
      + user                           = "carol"
    }

  # aws_iam_user.carol will be created
  + resource "aws_iam_user" "carol" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "carol"
      + path          = "/"
      + tags_all      = (known after apply)
      + unique_id     = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_user.carol: Creating...
aws_iam_user.carol: Creation complete after 2s [id=carol]
aws_iam_access_key.carol_key: Creating...
aws_iam_access_key.carol_key: Creation complete after 1s [id=AKIAQSCRAQJDWEEF5AEL]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Carol's access key and secret are now in the `terraform.tfstate` file. Open the file and note them. Now we can use the keys to log in to AWS using the CLI and see if we can access the Person table. Instead of rerunning `aws configure` and changing your default credentials, let's just pass Carol's keys into the CLI for one command. In the Docker terminal run the command below, replacing the keys inside single quotes:

```bash
AWS_ACCESS_KEY_ID='<Carol's access key>' AWS_SECRET_ACCESS_KEY='<Carol's secret access key>' aws s3 ls
```

As expected, Carol does not yet have database access.

```bash
An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
```

### Create a role

Add the following code to your `main.tf` file to create a role that access to the DynamoDB table that Carol can assume. Update the `Principal` with your account number, and the `DateLessThan` to be tomorrow.

```terraform
resource "aws_iam_role" "dbreader" {
  name = "dbreader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          "AWS": "arn:aws:iam::<Your Account Number>:root"
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
```

The resource creates the role for your account with an expiry date. The second resource is a permission to access DynamoDB, with a link to the AWS resource `name` of the Terraform role called `dbreader` created above. This is an example of how Terraform configuration files abstract the details of the underlying cloud provider: we're using the config file name of the resource, not AWS name.

Run `terraform apply`.

### Request access to the database

We now have a role with a permission to read the database, and a user, Carol. But Carol does not have permissions to assume roles. If she wants to access the Person table she must email an AWS administrator at her company to ask for access.

As the administrator, you need to add the code below to the configuration file and run `terraform apply` again. Update the `DateLessThan` value to tomorrow.

```terraform
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
```

### Read the database with the user using the role in the CLI

Carol can now assume the `dbreader` role in the CLI. To see this, run the following command in the terminal, replacing your keys and account number:

```bash
AWS_ACCESS_KEY_ID='<Carol's access key>' AWS_SECRET_ACCESS_KEY='<Carol's secret access key>' aws sts assume-role --role-arn "arn:aws:iam::<ACCOUNT_ID>:role/dbreader" --role-session-name "CarolSession"
```

AWS will return temporary credentials that look like the below:

```bash
"Credentials": {
        "AccessKeyId": "IAQSCRAQJDTNAC",
        "SecretAccessKey": "ozJXhWZNrpPyvttxqV5HE5gzn",
        "SessionToken": "2luX2VjEIn//////////wEaCIMEYCIQCuOjdHxeoGsoIQiN+kooZVF+UOyBz8=",
        "Expiration": "2023-11-08T17:30:31+00:00"
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "AROAQSCRAQJDQTYW57TM2:CarolSession",
        "Arn": "arn:aws:sts::08460:assumed-role/dbreader/CarolSession"
    }
}
```

Run the following command for Carol to access the DynamoDB table, but use the access key and secret key returned in the session credentials above:

```bash
AWS_ACCESS_KEY_ID='<Session access key>' AWS_SECRET_ACCESS_KEY='<Session secret access key>' AWS_SESSION_TOKEN='<Session token></Session>' aws dynamodb scan --table-name Person --region eu-west-1
```

Be sure to remove newlines from your session token or the command will fail. The output should be:

```bash
{
    "Items": [
        {
            "Id": {
                "S": "1"
            },
            "Email": {
                "S": "alice@example.com"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

Terraform has successfully given Carol temporary access to read the table for Alice's email address.

Carol's access to the database will automatically expire tomorrow, if the administrator set the correct condition in the policy.

## Advantages and disadvantages of Terraform

The advantages of using Terraform in our example, over AWS alone, are
- It's faster to add text to a configuration file and run `apply` than use the AWS web console. ChatGPT can provide the correct syntax for any configuration you need too.
- Your configuration files are stored in code, and so can be verified for safety and run by automated tools in a build pipeline.
- Your AWS state is recorded in a state file, so you can see exactly what is live at any time without having to browse AWS.

The main disadvantage of Terraform is having to manage your `terraform.tfstate` file. It must be kept safe, but not locally (because every administrator needs to use the latest version to avoid Terraform believing it has the incorrect state when running), and not in Git. You also might want to split your state file into modules to make it easier to understand to large configurations.

The other difficulty in this example is the manual process required for a user to request database access from an administrator, and the potential for human error when the administrator grants expiring permissions.

## What is Abbey, and how does it make this easier?

Abbey is [free](https://www.abbey.io/pricing/) for teams of twenty people or fewer.

### Install Abbey

In the AWS web console for the IAM service:
- Create a group called `readergroup`, with the permission `AmazonDynamoDBReadOnlyAccess`.

Install Abbey:
- Register an account at https://accounts.abbey.io/sign-up.
- Under "Settings" — "API Tokens", create a new Abbey API key. (Although the tab is called "API Tokens" and the buttons are called "API Keys", don't be confused — these terms mean the same thing. Note that Abbey's [documentation on keys ](https://docs.abbey.io/admin/managing-api-keys#creating-new-api-keys) refers you to a "Developers" tab that does not exist. Rather follow this tutorial.)
- Browse to https://github.com/abbeylabs/abbey-starter-kit-aws-iam.
- Click "Use this template" → "Create a new repository". This will fork the repository to your GitHub account.
- Make it a private repository for safety and name it `abbeytest`.
- Clone the repository to your computer into the `workspace\abbeytest` folder.

Note that Terraform's list of [starter kit repositories](https://github.com/orgs/abbeylabs/repositories?language=&q=abbey-starter-kit&sort=&type=all) contains both `abbey-starter-kit-terraform-cloud` and `abbey-starter-kit-aws-iam`. Even though the AWS kits don't mention Terraform in their name, all kits use Terraform. Don't use the Terraform cloud kit, as that is a paid Terraform service.

Add your AWS access keys to the GitHub repository.
- Browse to your `abbeytest` repository and click the "Settings" tab.
- Click "Secrets and variables" — "Actions".
- Click "New repository secret".
  - Set the "Name" to `AWS_ACCESS_KEY_ID`
  - Set the "Secret" to the Bob's access key from earlier. (Remember Bob is now an AWS administrator).
  - Click "Add secret"
- Add two more secrets in a similar way:
  - `AWS_SECRET_ACCESS_KEY` set to Bob's secret key
  - `ABBEY_TOKEN` set to the API key you created after registering on the Abbey website.

![GitHub Abbey secrets](./assets/secret.jpg)

- Browse to https://app.abbey.io/connections.
- Click "Create a Connection".
- Name it `abbeytest` and click "Create".
- Select "Only select repositories", select `abbeytest`, and click "Install & Authorize".
  ![Abbey connected to GitHub](./assets/abbeyConnection.jpg)

In the cloned repository you have a new Terraform configuration file, `workspace/abbeytest/main.tf`. Open it and take a look. You can see that Abbey and AWS are present as Terraform providers at the top. The majority of the configuration is the `resource "abbey_grant_kit" "IAM_membership" {` section. A grant kit consists of:
- A name and description
- A workflow, which can have several steps that regulate how access is given. In our file, it's a simple one step approval by an administrator.
- A policy, which is not present in our file, but has conditions that can automatically deny a user access to a resource to save adminstrators time.
- An output, which describes what should happen if access is approved. In our file, Abbey gives access by adding a user to a group in the `access.tf` configuration file.

At the bottom, the file contains resources. This could be a database or role. In our case the resource is a user group.

Let's change this grant starter kit to match the particulars of your AWS account:
- Change the `provider` to Ireland:
  ```terraform
  provider "aws" { region = "eu-west-1" }
  ```
- Change `reviewers` to the email address you used to register on `accounts.abbey.io`:
  ```terraform
  reviewers = { one_of = ["yourname@example.com"] }
  ```
- Change the `output` `location` to the `abbeytest` GitHub repository URL:
  ```terraform
  location = "github://yourname/abbeytest/access.tf"
  ```
- Change the `user_1` identity email to your Abbey email address. (In this simple case, you're using the same email address for the reviewer (administrator) and the requester. In reality, you would add every employee in your organisation as a separate user in this file with their own email address.)
  ```terraform
  abbey_account = "yourname@example.com"
  ```
- Set the IAM name to Carol, who you created in the previous section:
  ```terraform
  name = "carol"
  ```
- Set the group resource at the bottom of the file to `readergroup`:
  ```terraform
  data "aws_iam_group" "group1" {  # <- don't change this
    group_name = "readergroup" # <- change this
  }
  ```
- Save the `main.tf` file and commit and push to GitHub.
- Browse to [https://github.com/<yourname>/abbeytest/actions](https://github.com/<yourname>/abbeytest/actions) and see that Abbey's Terraform action ran `apply` when you committed.

### Make an access request with Abbey

- Browse to https://app.abbey.io/resources
  ![Request access in Abbey](./assets/request.jpg)
- Request access. You will receive an email:
  ![Access requested email](./assets/requestEmail.jpg)
- Abbey will check if the request passes all policies. You will receive another email:
  ![Checks passed email](./assets/checksPassed.jpg)

<!-- - Access will be immediately rejected. You will receive an email:
  ![Request denied email](./assets/requestDenied.jpg) -->

- In the Abbey "Approvals" screen, click "Approve".
  ![Approve the request](./assets/approve.jpg)


You can see the GitHub actions Abbey ran to add Carol to the group in your repository's "Actions" tab — https://github.com/YourName/abbeytest/actions.

Abbey makes access changes only through GitHub on commits. If you try to run Terraform locally it will fail because you do not have a state file. Even running `terraform init` will fail with:
```bash
Initializing the backend...
Error refreshing state: HTTP remote state endpoint requires auth
```

### Read the database with the user using the group in the CLI

Carol is now part of the `readergroup`. Check that she can read the database in the CLI:

```bash
AWS_ACCESS_KEY_ID='<Carol's access key>' AWS_SECRET_ACCESS_KEY='<Carol's secret access key>' aws dynamodb scan --table-name Person --region eu-west-1
```

If you udpate the `abbeytest` repository from GitHub, you'll see a new file, `workspace/abbeytest/access.tf`. This is where Abbey maintains your access configuration:

```terraform
resource "aws_iam_user_group_membership" "user_carol_group_readergroup" {
  user = "carol"
  groups = ["readergroup"]
}
```

### Revoke permissions

In the Abbey "Approvals" screen, click "Revoke".
  ![Revoke permissions](./assets/revoke.jpg)

After waiting two minutes for Abbey to run the GitHub action to revoke access, you'll see that Carol can no longer read the database:

```bash
AWS_ACCESS_KEY_ID='<Carol's access key>' AWS_SECRET_ACCESS_KEY='<Carol's secret access key>' aws dynamodb scan --table-name Person --region eu-west-1
```

And `workspace/abbeytest/access.tf` will now be blank once more.

## Delete your temporary administrator

If you've been following along with this tutorial, delete user Bob, so that his administrator permissions cannot be exploited.

### How exactly does Abbey work?

Abbey has two components:
- The Abbey web application
- Your GitHub repository with the Terraform configuration files.

Users and administrators interact with the app to request, approve, and revoke access.

When Abbey approves access, the app commits code to the GitHub repository, which runs a GitHub Action to run `terraform apply` using the Terraform state that is kept securely in the Abbey web server. No administrators in your company can see the secrets in the state file, but Abbey administrators have access to all your company's secrets.

Abbey organizes this process with the following concepts:
- Workflow: How someone requests access and who approves them.
- Policies: Whether someone should automatically be denied access, and when their access should be automatically revoked.

### What are the benefits of Abbey over using Terraform alone?

- Simplicity: The initial configuration of Abbey will take a while, but after that users can see all resources on a single page, and request access in a single click, while administrators can grant it in another click. You no longer need to rely solely on email.
- Auditing: Abbey stores all access requests and changes in your GitHub repository as pull requests, actions, and code merges. You can use this as an audit history to know who had access to a resource at any point in time.
- Reduction of human error: Since granting access is automated, administrators no longer have to adjust Terraform configuration files manually and then apply them. This reduces the chance that access will be incorrectly set.

### What are the disadvantages of Abbey?

- Unlike Terraform/OpenTofu, Abbey has no free local version. For companies of more than twenty users, you need to pay for the service.
- You can use it only on the Abbey website. If Abbey's site goes offline, you will no longer be able to manage your access through them.

You aren't locked in to the service, however. If you wish to stop using Abbey, you can simply unlink your Abbey account from your GitHub repository and return to managing your users manually with Terraform or AWS alone.

### What are the alternatives to Abbey for access governance?

- Entitle.io claim to have a similar service, but have no free demo for us to try. They are also three times more expensive at the time of writing. Entitle charges [charge $360 000 for 500 users for a year](https://aws.amazon.com/marketplace/pp/prodview-kddzmmhfdezso), where you would pay only $120 000 for Abbey.
- Sailpoint.com is similar, with no trial, and [charging $165 000](https://aws.amazon.com/marketplace/pp/prodview-pz66rdhrnioru).
- VaultOne.com looks like it might do something similar, but we can't find detailed pricing or feature information on their site.

In contrast, Abbey.io is transparent about their pricing and features, and is simple to set up and test for yourself. They are dedicated to access governance in Terraform, and were easy to use to write this article. Unless you need more than that, they're probably all you need for your organization.

## Questions for Abbey
- What does "Use this template — Create a new repository" do in GitHub? It seemed to have the same effect as forking the repository. If different, what extra stuff is it doing? If the same, why not use the fork button?
- How exactly does the workflow work?
- Where is the `terraform.tfstate` file kept? It's not in github. If it's kept in the Abbey server, then what's preventing Abbey admins from having full access to my company's access keys and performing harmful actions authenticated as me?
- Where do I keep this GitHub repo in relation to my existing Terraform repository folder?
- Why can't I manage user in Abbey website? It says `User metadata is unavailable. Set up Directory Sync to view user metadata`.
- Is there localhost version of Abbey, like Terraform?
- What can't it manage? I assume it can handle — users, groups, roles. But not databases, apps, secrets?
- Who are your competitors and why are you better?
  - https://sourceforge.net/software/product/Abbey/alternatives
  - https://slashdot.org/software/p/Abbey/alternatives
  - (Entitle.io is 36x more pricey. Sailtpoint? VaultOne? They don't really explain whta they do)

## Problems with Abbey
Here are some problems/confusions I had as a new user trying to follow the tutorial for AWS:
- API Key <> API Token in their Settings page. Why are there two names?
- Documentation on API Keys says there is a Developer tab, which doesn't exist.
- Their documentation has language errors and should be run through a grammar checker:
  - "or when access should be revoke"
  - "write arbitrary rules via it's support of Open Policy Agent"
- In the https://docs.abbey.io/getting-started/tutorials/aws-managing-access-to-iam-groups tutorial, they never tell you what to call the group you create in IAM, or to change the name in the `main.tf` file to match it, so the GitHub action will always fail whenever you commit. That tutorial will be broken until it's updated to include this.

## Todo
- add diagrams
- add links
- Is abbey hosted locally or on their servers?
- What Abbey offers on top of this either in terms of
- Extra features (more control)
- Simpler / easier?
- More compliance?
- Single interface to manage access to all resources, not just AWS (e.g. Snowflake).
