## Resources
- Repository — https://github.com/ritza-co/abbey
- Article proposal — https://docs.google.com/document/d/1Z7XxAVgjyQFsvkMGOyW_jW5aMZ7c5g6Nd_yNN9MqLN0/edit
- Publication target — https://www.aptible.com/blog
- Copy this article — https://spacelift.io/blog/terraform-iam-role
- Abbey — https://www.abbey.io/
- How to use Abbey with AWS — https://docs.abbey.io/getting-started/tutorials/aws-managing-access-to-iam-groups
- Gareth used IAM, Niel used Terraform, Bradley used SOC2

## Steps
- [x] Create article outline
- [x] Create AWS account
    - https://eu-west-1.console.aws.amazon.com/console/home?region=eu-west-1#
- [x] Create budget to prevent incurring costs
  - [x] Use simple template for zero cost budget
- [x] Create IAM user that can use SimpleDB
- [x] Make "hello world" SimpleDB app
- [x] Run through the [Spacelift](https://spacelift.io/blog/terraform-iam-role) blog post to discover anything wrong or outdated
- [x] Come up with a basic scenario to demonstrate using terraform + IAM to create and manage users/roles
- [x] Create the terraform code and steps needed to run through the scenario
- [x] Sign up for a free trial on Abbey
- [ ] Try out one of their hello world examples if possible
- [ ] Figure out what extra value Abbey provides. Mention that and link to the existing Abbey IAM guide at end of article

## Article plan
- How to create user and role to access dynamodb table to read data in AWS IAM. And revoke permissions.
- How to do it in Terraform
  - User requests access
  - Admin approves it and configures it
  - Admin revokes it
- How to do it in Abbey.io
  - What are the benefits of Abbey