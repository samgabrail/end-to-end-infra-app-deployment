# Outputs file
output "jenkins_public_ip" {
  value = azurerm_public_ip.jenkins-pip.fqdn
}

