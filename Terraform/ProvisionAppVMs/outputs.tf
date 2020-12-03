# Outputs file
output "webblog_public_dns" {
  value = azurerm_public_ip.webblog-pip.fqdn
}
