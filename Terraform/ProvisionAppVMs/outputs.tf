# Outputs file
output "webblog_public_dns" {
  value = {
  for ip in azurerm_public_ip.webblog-pip:
  ip.name => ip.fqdn
  }
  // value = [azurerm_public_ip.webblog-pip.*.fqdn]
}
