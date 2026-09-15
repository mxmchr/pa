############################################
### Workloads - vague 0                   ###
############################################



admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGscX6++HvMMG47HZLaR6YXwj9aqs5uDIxao67cz6UI+ proxmox-iac"

lxcs = {
  pdns1 = {
    vm_id            = 120
    hostname         = "pdns1"
    tags             = ["dns", "srv"]
    node_name        = "pve1"
    cores            = 1
    memory_size      = 512
    swap_size        = 512
    network_bridge   = "SRV"
    ipv4_address     = "10.0.20.5/24"
    ipv4_gateway     = "10.0.20.1"
    disk_size        = 8
    startup_order    = 2
  }

  pdns2 = {
    vm_id            = 121
    hostname         = "pdns2"
    tags             = ["dns", "srv"]
    node_name        = "pve2"
    cores            = 1
    memory_size      = 512
    swap_size        = 512
    network_bridge   = "SRV"
    ipv4_address     = "10.0.20.6/24"
    ipv4_gateway     = "10.0.20.1"
    disk_size        = 8
    startup_order    = 2
  }

  openbao = {
    vm_id            = 122
    hostname         = "openbao"
    tags             = ["secrets", "pki", "srv"]
    node_name        = "pve3"
    cores            = 1
    memory_size      = 512
    swap_size        = 512
    network_bridge   = "SRV"
    ipv4_address     = "10.0.20.10/24"
    ipv4_gateway     = "10.0.20.1"
    disk_size        = 8
    startup_order    = 3
  }

  authentik = {
    vm_id            = 123
    hostname         = "authentik"
    tags             = ["identity", "srv"]
    node_name        = "pve2"
    cores            = 2
    memory_size      = 1536
    swap_size        = 1024
    network_bridge   = "SRV"
    ipv4_address     = "10.0.20.15/24"
    ipv4_gateway     = "10.0.20.1"
    disk_size        = 16
    startup_order    = 4
    keyctl           = false
  }

  traefik = {
    vm_id            = 124
    hostname         = "traefik"
    tags             = ["proxy", "srv"]
    node_name        = "pve1"
    cores            = 1
    memory_size      = 512
    swap_size        = 512
    network_bridge   = "SRV"
    ipv4_address     = "10.0.20.20/24"
    ipv4_gateway     = "10.0.20.1"
    disk_size        = 8
    startup_order    = 4
  }
}

vms = {
    netbird = {
    name        = "netbird"
    vm_id       = 130
    node_name   = "pve3"
    tags        = ["vpn", "dmz"]
    cores       = 2
    memory_size = 2048
    disk_size   = 20
    network_devices = [
      { bridge = "DMZ", mtu = 1450 },
    ]
    ipv4_address  = "10.0.30.5/24"
    ipv4_gateway  = "10.0.30.1"
    startup_order = 5
  }

  peer1 = {
    name        = "peer1"
    vm_id       = 131
    node_name   = "pve1"
    tags        = ["vpn", "dmz"]
    cores       = 1
    memory_size = 768
    disk_size   = 8
    network_devices = [
      { bridge = "DMZ", mtu = 1450 },
    ]
    ipv4_address  = "10.0.30.10/24"
    ipv4_gateway  = "10.0.30.1"
    startup_order = 6
  }

  peer2 = {
    name        = "peer2"
    vm_id       = 132
    node_name   = "pve2"
    tags        = ["vpn", "dmz"]
    cores       = 1
    memory_size = 768
    disk_size   = 8
    network_devices = [
      { bridge = "DMZ", mtu = 1450 },
    ]
    ipv4_address  = "10.0.30.11/24"
    ipv4_gateway  = "10.0.30.1"
    startup_order = 7
  }
  
  pbs = {
    name  = "pbs"
    vm_id = 150
    tags  = ["backup", "bck"]

    cores       = 2
    memory_size = 1024
    disk_size   = 32

    network_devices = [
      { bridge = "BCK" },
    ]

    ipv4_address = "10.0.50.5/24"
    ipv4_gateway = "10.0.50.1"

    node_name = "pve3"

    startup_order = 2
  }
}

opnsense = {
  iso_file_id     = "local:iso/OPNsense-26.7-dvd-amd64.iso"
  wan_mac_address = "BC:24:11:47:98:8A"

  segments = [
    { name = "LAN", bridge = "LAN", mac_address = "BC:24:11:6E:A9:79" },
    { name = "SRV", bridge = "SRV", mac_address = "BC:24:11:A0:25:F4" },
    { name = "DMZ", bridge = "DMZ", mac_address = "BC:24:11:B1:A2:78" },
    { name = "ADM", bridge = "ADM", mac_address = "BC:24:11:80:39:88" },
    { name = "BCK", bridge = "BCK", mac_address = "BC:24:11:ED:EE:C9" },
    { name = "DEV", bridge = "DEV", mac_address = "BC:24:11:C5:AD:FE" },
    { name = "PUB", bridge = "PUB", mac_address = "BC:24:11:97:ED:47" },
  ]
}