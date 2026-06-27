output "vm_public_ip" {
  description = "Public IP address of the web VM — use this to SSH and to browse the site"
  value       = azurerm_public_ip.web.ip_address
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.web.name
}

output "resource_group_name" {
  description = "Resource group that contains all resources"
  value       = azurerm_resource_group.main.name
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.web.ip_address}"
}
