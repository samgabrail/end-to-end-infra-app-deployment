# Create the Webblog App VMs

## Retrieve Azure Creds from Vault
Make sure you're logged into Vault
```shell
vault read azure/creds/jenkins
```

Jenkins will retrieve the Azure creds from Vault and then use those in the command below:

```shell
terraform apply -var 'client_id=foo' -var 'client_secret=bar' --auto-approve
```