# terraform

## Link to GIT:
https://github.com/ArberBajraktari/terraform.git

## Workshop 1 and 2
These workshops can be found on the archive folder.

## Why do we need Terraform Cloud (or another backend) when we use CI/CD?
We were not able to do this in practice, but we will try to answer it in theory at the very least. 
By using Terraform cloud we can kinda centralise the services, platforms and also the infrastructure and use them from here all in one location.
Also the terraform.tfstate and terraform.tfstate.backup are ignored in github, but in Terraform Cloud they are rather used.