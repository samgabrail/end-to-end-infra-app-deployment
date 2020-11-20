# Packer image for Ubuntu 18.04 LTS on Azure

Add the Azure creds to the `variables.json` file

## Creating the Packer Image
To create the template image execute
```shell
packer build -force -var-file variables.json ubuntu18.json
```
