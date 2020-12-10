terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
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

data "azurerm_resource_group" "myresourcegroup" {
  name = "${var.prefix}-jenkins"
}

data "azurerm_image" "docker-image" {
  name                = "samg-Docker"
  resource_group_name = data.azurerm_resource_group.myresourcegroup.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = data.azurerm_resource_group.myresourcegroup.location
  address_space       = [var.address_space]
  resource_group_name = data.azurerm_resource_group.myresourcegroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.myresourcegroup.name
  address_prefixes       = [var.subnet_prefix]
}


resource "azurerm_network_security_group" "jenkins-sg" {
  name                = "${var.prefix}-sg"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.myresourcegroup.name

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

resource "azurerm_network_interface" "jenkins-nic" {
  name                      = "${var.prefix}-jenkins-nic"
  location                  = var.location
  resource_group_name       = data.azurerm_resource_group.myresourcegroup.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins-pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins-sga" {
  network_interface_id      = azurerm_network_interface.jenkins-nic.id
  network_security_group_id = azurerm_network_security_group.jenkins-sg.id
}

resource "azurerm_public_ip" "jenkins-pip" {
  name                = "${var.prefix}-ip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.myresourcegroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.prefix}-jenkins"
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "${var.prefix}-jenkins"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.myresourcegroup.name
  size                = var.vm_size
  admin_username      = "adminuser"

  tags = local.common_tags
  
  network_interface_ids         = [azurerm_network_interface.jenkins-nic.id]
  // Add a public key to the same folder as the main.tf script (we use Ansible to send the private key to the Jenkins machine)
  admin_ssh_key {
    username   = var.adminuser
    public_key = file("id_rsa.pub")
  }

  source_image_id = data.azurerm_image.docker-image.id

  os_disk {
    name                  = "${var.prefix}-osdisk"
    storage_account_type  = "Standard_LRS"
    caching               = "ReadWrite"
  }
  
}

// resource "null_resource" "run-jenkins-docker" {
//   depends_on = [
//     azurerm_linux_virtual_machine.jenkins
//   ]

//   triggers = {
//     build_number = timestamp()
//   }

//   provisioner "remote-exec" {
//     inline = [
//       "sudo docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 samgabrail/jenkins-tf-vault-ansible:latest"
//     ]

//     connection {
//       type     = "ssh"
//       user     = var.adminuser
//       private_key = file("/home/sam/.ssh/id_rsa")
//       host     = azurerm_public_ip.jenkins-pip.fqdn
//     }
//   }
// }
