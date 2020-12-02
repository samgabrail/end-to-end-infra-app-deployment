# Create a Jenkins VM

## Retrieve Azure Creds from Vault
Make sure you're logged into Vault
```shell
vault read azure/creds/jenkins
```

Place creds into the Terraform variables in TFC

This VM will have Docker installed via Packer. Then Ansible will pull and start a Docker image containing jenkins, ansible, vault, and terraform.