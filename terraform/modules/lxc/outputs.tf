output "vm_id" {
  description = "VMID du conteneur créé (consommé par terraform/live/03-ha)."
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "root_password" {
  value     = random_password.root_password.result
  sensitive = true
}

output "root_private_key" {
  value     = tls_private_key.root_key.private_key_pem
  sensitive = true
}

output "ssh_public_key" {
  value = tls_private_key.root_key.public_key_openssh
}