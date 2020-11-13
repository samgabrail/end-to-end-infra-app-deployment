# Overview

Here we trace the workflow of a developer deploying infrastructure and applications to Azure using Packer, GitHub, Jenkins, Terraform, Vault, Ansible, and Consul. We use our webblog application to demo this.

## Topics to Learn
1. Vault Azure Secrets Engine
2. Vault Secure Introduction
3. Vault App Role
4. Vault Dynamic Database Secrets for MongoDB
5. Vault Transit Secrets Engine
6. Advanced CI/CD Pipeline Workflow using GitHub(VCS), Jenkins(CI/CD), Terraform(IaC), Ansible(Config Mgmt), Vault(Secrets Mgmt)
7. Consul Service Mesh

## Vault Azure Secrets Engine
Let's take a look at how we can build this. You can find details in the [docs](https://www.vaultproject.io/docs/secrets/azure). You can also follow the [step-by-step guide](https://learn.hashicorp.com/tutorials/vault/azure-secrets).

Below is a diagram of the Vault Azure Secrets Engine Workflow

![Vault Azure Secrets Engine Workflow Diagram](https://learn.hashicorp.com/img/vault-azure-secrets-0.png)

### Vault Configuration

The configuration setup below needs to be done by a Vault Admin. The [Vault policy](https://learn.hashicorp.com/tutorials/vault/azure-secrets#policy-requirements) `Vault/policies/azure_admin_policy.hcl` is used with a token to run the configuration commands. We use the root token in this demo for simplicity, however, in a production setting it's not recommended to use the root token.

We are re-using our existing Vault cluster. The Vault admin configuration is located in the [infrastructure-gcp GitLab repo](https://gitlab.com/public-projects3/infrastructure-gcp/-/tree/master/terraform-vault-configuration)

#### Setup

1. Enable the Azure secrets engine
   ```shell
   vault secrets enable azure
   ```

2. Configure the secrets engine with account credentials
   ```shell
   vault write azure/config \
    subscription_id=$AZURE_SUBSCRIPTION_ID \
    tenant_id=$AZURE_TENANT_ID \
    client_id=$AZURE_CLIENT_ID \
    client_secret=$AZURE_CLIENT_SECRET
   ```

3. Configure a role
   ```shell
    vault write azure/roles/edu-app ttl=1h azure_roles=-<<EOF
    [
      {
        "role_name": "Contributor",
        "scope": "/subscriptions/<Subscription_ID>/resourceGroups/vault-education"
      }
    ]
    EOF
   ```