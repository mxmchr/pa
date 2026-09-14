output "vm_id" {
  description = "VMID du conteneur, consommé par terraform/live/03-ha."
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "hostname" {
  description = "Hostname, pour génération de l'inventaire Ansible."
  value       = var.hostname
}

output "ipv4_address" {
  description = "Adresse IPv4, pour génération de l'inventaire Ansible."
  value       = var.ipv4_address
}

output "root_password" {
  description = "Mot de passe root généré. Accès de secours."
  value       = random_password.root_password.result
  sensitive   = true
}

output "root_private_key" {
  description = "Clé privée générée, au format OpenSSH. Accès de secours."
  value       = tls_private_key.root_key.private_key_openssh
  sensitive   = true
}

output "ssh_public_key" {
  description = "Clé publique correspondante."
  value       = tls_private_key.root_key.public_key_openssh
}