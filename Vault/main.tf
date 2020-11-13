terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "2.15.0"
    }
  }
}

provider "vault" {
  # Configuration options
}

resource "vault_policy" "jenkins_policy" {
  name   = "jenkins"
  policy = file("policies/jenkins_azure_policy.hcl")
}

// WebBlog Config

resource "vault_policy" "webblog" {
  name   = "webblog"
  policy = file("policies/webblog_policy.hcl")
}

resource "vault_mount" "db" {
  path = "mongodb"
  type = "database"
  description = "Dynamic Secrets Engine for WebBlog MongoDB."
}

resource "vault_database_secret_backend_connection" "mongodb" {
  backend       = vault_mount.db.path
  name          = "mongodb"
  allowed_roles = ["mongodb-role"]

  mongodb {
    connection_url = "mongodb://${var.DB_USER}:${var.DB_PASSWORD}@${var.DB_URL}/admin"
    
  }
}

resource "vault_database_secret_backend_role" "mongodb-role" {
  backend             = vault_mount.db.path
  name                = "mongodb-role"
  db_name             = vault_database_secret_backend_connection.mongodb.name
  default_ttl         = "10"
  max_ttl             = "86400"
  creation_statements = ["{ \"db\": \"admin\", \"roles\": [{ \"role\": \"readWriteAnyDatabase\" }, {\"role\": \"read\", \"db\": \"foo\"}] }"]
}

resource "vault_mount" "transit" {
  path                      = "transit"
  type                      = "transit"
  description               = "To Encrypt the webblog"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "key" {
  backend = vault_mount.transit.path
  name    = "webblog-key"
  derived = "true"
  convergent_encryption = "true"
}

