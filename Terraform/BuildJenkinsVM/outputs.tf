# Outputs file
output "jenkins_public_dns" {
  value = azurerm_public_ip.jenkins-pip.fqdn
}

output "jenkins_public_ip" {
  value = azurerm_public_ip.jenkins-pip.ip_address
}