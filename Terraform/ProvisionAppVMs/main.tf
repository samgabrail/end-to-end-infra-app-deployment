terraform {
  backend "remote" {
    organization = "HashiCorp-Sam"
    workspaces {
      name = "end-to-end-infra-app-deployment-webblog-app-azure"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.36.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}

locals {
  se-region = "AMER - Canada"
  owner     = "sam.gabrail"
  purpose   = "demo for end-to-end infrastructure and application deployments"
  ttl       = "-1"
  terraform = "true"
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    se-region = local.se-region
    owner     = local.owner
    purpose   = local.purpose
    ttl       = local.ttl
    terraform = local.terraform
  }
}

// Using the same resource group because our Vault Azure secrets is tied to this specific resource group

data "azurerm_resource_group" "jenkinsresourcegroup" {
  name = "${var.prefix}-jenkins"
}

data "azurerm_image" "docker-image" {
  name                = "samg-Docker"
  resource_group_name = data.azurerm_resource_group.jenkinsresourcegroup.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.app-prefix}-vnet"
  location            = data.azurerm_resource_group.jenkinsresourcegroup.location
  address_space       = [var.address_space]
  resource_group_name = data.azurerm_resource_group.jenkinsresourcegroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-${var.app-prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.jenkinsresourcegroup.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "webblog-sg" {
  name                = "${var.prefix}-${var.app-prefix}-sg"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.jenkinsresourcegroup.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Mongo"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8300-8600"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Envoy"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "21000-21255"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "webblog-nic" {
  // count               = var.node_count
  for_each = var.vm_names
  name                = "${var.prefix}-${var.app-prefix}-${each.key}-nic"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.jenkinsresourcegroup.name

  ip_configuration {
    name                          = "${var.prefix}-${var.app-prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.webblog-pip.*.id, each.key)
  }
}

resource "azurerm_subnet_network_security_group_association" "webblog_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.webblog-sg.id
}

resource "azurerm_public_ip" "webblog-pip" {
  // count               = var.node_count
  for_each = var.vm_names
  name                = "${var.prefix}-${var.app-prefix}-${each.key}-ip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.jenkinsresourcegroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.prefix}-${var.app-prefix}-${each.key}"
}

resource "azurerm_linux_virtual_machine" "webblog" {
  // count               = var.node_count
  for_each = var.vm_names
  name                = "${var.prefix}-${var.app-prefix}-${each.key}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.jenkinsresourcegroup.name
  size                = var.vm_size
  admin_username      = "adminuser"

  tags = local.common_tags

  network_interface_ids = [element(azurerm_network_interface.webblog-nic.*.id, each.key)]
  // Add a public key to the same folder as the main.tf script (we use Ansible to send the private key to the Jenkins machine)
  admin_ssh_key {
    username   = var.adminuser
    public_key = file("id_rsa.pub")
  }

  source_image_id = data.azurerm_image.docker-image.id

  os_disk {
    name                 = "${var.prefix}-${var.app-prefix}-${each.key}-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}