# Packer image for Ubuntu 18.04 LTS on Azure

## Retrieve Azure Creds from Vault
Make sure you're logged into Vault
```shell
vault read azure/creds/jenkins
```

Then add the Azure creds to the `variables.json` file

## Creating the Packer Image
To create the template image execute
```shell
packer build -var-file variables.json ubuntu18.json
```
