output "vm_id" {
  description = "VMID de la VM, consommé par terraform/live/03-ha."
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  description = "Nom de la VM, pour génération de l'inventaire Ansible."
  value       = var.name
}

output "ipv4_address" {
  description = "Adresse de la première interface, pour l'inventaire Ansible."
  value       = var.cloud_init ? var.ipv4_address : null
}

output "mac_addresses" {
  description = <<-EOT
    Adresses MAC attribuées, dans l'ordre des cartes. Nécessaires pour toute
    configuration désignant une carte précise dans l'invité, l'ordre des
    périphériques vus par celui-ci dépendant de l'énumération PCI.
  EOT
  value       = proxmox_virtual_environment_vm.this.mac_addresses
}

output "username" {
  description = "Compte cloud-init. null pour une appliance."
  value       = var.cloud_init ? var.cloud_init_username : null
}

output "root_password" {
  description = "Mot de passe du compte cloud-init. null pour une appliance."
  value       = var.cloud_init ? random_password.root_password[0].result : null
  sensitive   = true
}

output "root_private_key" {
  description = "Clé privée du compte cloud-init, au format OpenSSH."
  value       = var.cloud_init ? tls_private_key.root_key[0].private_key_openssh : null
  sensitive   = true
}

output "ssh_public_key" {
  description = "Clé publique correspondante."
  value       = var.cloud_init ? tls_private_key.root_key[0].public_key_openssh : null
}