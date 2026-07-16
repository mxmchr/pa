output "lxc_vm_ids" {
  description = "vmid des conteneurs LXC créés, par clé (pour consommation par terraform/live/03-ha)"
  value       = { for k, v in module.lxc : k => v.vm_id }
}

output "vm_vm_ids" {
  description = "vmid des VM QEMU créées, par clé (pour consommation par terraform/live/03-ha)"
  value       = { for k, v in module.vm : k => v.vm_id }
}
