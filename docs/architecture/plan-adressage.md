# Plan d'adressage IP

Domaine interne : **pa.lan**

## Underlay inter-Proxmox (172.16.0.0/16, un /24 par usage, en partant de .255 et en descendant)

Ces réseaux ne portent pas de trafic client : mgmt, corosync (heartbeat) et Ceph.
Chaque nœud PVE a une IP fixe (`.11` = pve1, `.12` = pve2, `.13` = pve3) dans chacun de ces /24.

| Réseau         | NIC (cf. table MAC)   | CIDR              | pve1        | pve2        | pve3        |
|----------------|------------------------|--------------------|-------------|-------------|-------------|
| mgmt           | mgmt                   | 172.16.255.0/24    | .11 *(existant)* | .12 *(existant)* | .13 *(existant)* |
| corosync       | corosync                | 172.16.254.0/24    | .11         | .12         | .13         |
| ceph_public    | ceph_public              | 172.16.253.0/24    | .11         | .12         | .13         |
| ceph_cluster   | ceph_cluster             | 172.16.252.0/24    | .11         | .12         | .13         |
| sdn_trunk      | sdn_trunk                | — (trunk 802.1Q, pas d'IP niveau OS, porte les VLAN ci-dessous) | — | — | — |

> `mgmt` est déjà en place (`ANSWER_PVE1.TOML` → `172.16.255.11/24`). Les trois autres /24 sont à créer via le rôle Ansible `pve_network` (phase 01) sur les 4 NIC restantes de la table de MAC.

## VLAN SDN — trafic client (10.0.0.0/16, un /24 par VLAN, +10 à chaque fois)

| VLAN | Tag | CIDR         | Gateway    |
|------|-----|--------------|------------|
| LAN  | 10  | 10.0.10.0/24 | 10.0.10.1  |
| SRV  | 20  | 10.0.20.0/24 | 10.0.20.1  |
| DMZ  | 30  | 10.0.30.0/24 | 10.0.30.1  |
| ADM  | 40  | 10.0.40.0/24 | 10.0.40.1  |
| BCK  | 50  | 10.0.50.0/24 | 10.0.50.1  |
| DEV  | 60  | 10.0.60.0/24 | 10.0.60.1  |

Défini dans `terraform/live/01-fabric/variables.tf` (`var.sdn_zone`). Le tag VLAN reprend le 3ᵉ octet pour rester facile à retenir (VLAN 10 ↔ 10.0.**10**.0/24, etc.) — à ajuster si tu as déjà des tags VLAN imposés ailleurs sur ton switch physique.

## Ceph

- 2 disques OSD par nœud, nommage simple : `/dev/sdc` et `/dev/sdd` (en plus de `sda`/`sdb` en ZFS mirror pour le boot, déjà configuré dans les `answer.toml`).
- Réseau public Ceph : `172.16.253.0/24` — Réseau cluster/replication Ceph : `172.16.252.0/24`.

## Ouvert / à confirmer

- Bridge Proxmox exact à associer au NIC `sdn_trunk` (actuellement placeholder `vmbr0` dans `terraform/live/01-fabric/variables.tf`).
- Contrôleur EVPN / ASN / exit-node (non traité dans cette itération).
