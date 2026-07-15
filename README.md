# Proxmox Infrastructure as Code

Ce dépôt automatise le déploiement d'une plateforme **Proxmox VE** hyperconvergée
(3 nœuds, ZFS, Ceph, SDN) de A à Z : génération des médias d'installation,
formation du cluster, stockage Ceph, puis (à venir) réseau SDN/EVPN via
Terraform, tooling et Zero Trust.

Approche : tout en IaC, découpé en **phases numérotées**, chacune testable
indépendamment. Ansible pour tout ce qui est configuration système
(installation, cluster, réseau, Ceph, tooling), Terraform pour tout ce qui
est ressources Proxmox déclaratives (SDN, pools, VM/LXC).

---

# Structure du projet

```text
.
├── ansible/
│   ├── ansible.cfg
│   ├── collections/requirements.yml
│   ├── inventory/production/
│   │   ├── hosts.yml                  # pve1/pve2/pve3
│   │   ├── host_vars/                 # MAC par nœud (mgmt, corosync, ceph_public, ceph_cluster, sdn_trunk)
│   │   └── group_vars/
│   │       ├── all/vars.yml           # domaine, clavier, disques boot, chemins partagés
│   │       ├── all/vault.yml          # chiffré (ansible-vault) — mot de passe root, jamais commité en clair
│   │       └── proxmox/main.yml       # cluster, Ceph, ISO, réseau
│   ├── playbooks/
│   │   ├── 00-generate-answer-files.yml   # génère les ANSWER_PVEx.TOML (Jinja + vault)
│   │   ├── 00-prepare-install-media.yml   # télécharge l'ISO PVE + génère les ISO auto-installables
│   │   ├── 01-repositories.yml            # dépôts Proxmox/Ceph, upgrade
│   │   ├── 02-network.yml                 # interfaces dédiées Ceph (ceph_public, ceph_cluster)
│   │   ├── 03-cluster.yml                 # formation du cluster Proxmox
│   │   └── 04-ceph.yml                    # mon/mgr/OSD/pool Ceph
│   └── roles/
│       ├── pve_answer_file/           # phase 00
│       ├── pve_install_media/         # phase 00 (ISO, via conteneur Docker trixie)
│       ├── pve_repositories/          # phase 01
│       ├── pve_network/               # phase 02 (scopé Ceph pour l'instant)
│       ├── pve_cluster/               # phase 03
│       └── pve_ceph/                  # phase 04
├── terraform/
│   ├── modules/                       # pool, sdn_vlan, capabilities, lxc, vm
│   └── live/
│       ├── 01-fabric/                 # zones SDN (LAN/SRV/DMZ/ADM/BCK/DEV) — state isolé
│       ├── 02-workloads/              # pool, capabilities, LXC/VM — state isolé
│       └── 03-zero-trust/             # à venir
├── docs/
│   ├── architecture/plan-adressage.md # plan IP complet (underlay + VLAN SDN)
│   └── decisions/security-notes.md    # rotation du mot de passe root, gestion du vault
├── files/
│   ├── answer-files/                  # ANSWER_PVEx.TOML générés, gitignorés
│   ├── iso/                           # ISO PVE + ISO auto-installables, gitignorées
│   └── docker/pve-auto-install/       # image trixie pour proxmox-auto-install-assistant
└── README.md
```

---

# Prérequis

- 3 serveurs physiques (5 NIC chacun : mgmt, corosync, ceph_public, ceph_cluster, sdn_trunk)
- Un poste d'administration Linux (WSL ok) avec :
  - Python 3, `pip install ansible-core passlib`
  - `ansible-galaxy collection install -r ansible/collections/requirements.yml`
  - **Docker** (nécessaire à la phase `00-prepare-install-media` : `proxmox-auto-install-assistant`
    est buildé pour Debian trixie — glibc ≥ 2.39 — et ne s'installe pas nativement sur un
    control node plus ancien, ex. Debian 12 bookworm ; on le fait tourner dans un conteneur)

---

# Le mot de passe root (Ansible Vault)

Le mot de passe root des 3 nœuds n'est jamais stocké en clair dans le repo — il vit dans
`ansible/inventory/production/group_vars/all/vault.yml`, chiffré :

```bash
cd ansible
ansible-vault create inventory/production/group_vars/all/vault.yml
# contenu : vault_pve_root_password: "ton-mot-de-passe"
```

Toutes les commandes `ansible-playbook` ci-dessous nécessitent `--vault-password-file ../.vault_pass`
(fichier local, gitignoré) ou `--ask-vault-pass`.

---

# Ordre d'exécution

## 1. Générer les fichiers `answer.toml`

```bash
ansible-playbook playbooks/00-generate-answer-files.yml --vault-password-file ../.vault_pass
```

Produit `files/answer-files/ANSWER_PVE{1,2,3}.TOML` à partir du template Jinja et des MAC
déclarées en `host_vars/`. Le hash du mot de passe root (sha512-crypt) est recalculé à
chaque run à partir du vault — normal que la ligne change d'un run à l'autre.

## 2. Télécharger l'ISO et générer les médias d'installation

```bash
ansible-playbook playbooks/00-prepare-install-media.yml --vault-password-file ../.vault_pass
```

Télécharge `proxmox-ve_9.2-1.iso` (checksum vérifié), builde une image Docker `debian:trixie`
avec `proxmox-auto-install-assistant`, puis génère `files/iso/proxmox-ve-pve{1,2,3}.iso` —
chacune avec son `answer.toml` intégré. Pour forcer une regénération après modification
d'un answer.toml, supprime l'ISO correspondante avant de relancer.

## 3. Installer les 3 serveurs physiques

Graver/monter chaque `proxmox-ve-pveX.iso` sur son serveur correspondant et démarrer dessus
(installation entièrement automatique, aucune interaction).

## 4. Dépôts et dépendances

```bash
ansible-playbook playbooks/01-repositories.yml
```

## 5. Interfaces réseau dédiées à Ceph

```bash
ansible-playbook playbooks/02-network.yml
```

Configure `ceph_public` (172.16.253.0/24) et `ceph_cluster` (172.16.252.0/24) sur les NIC
dédiées. Voir `docs/architecture/plan-adressage.md` pour le plan complet.

## 6. Cluster Proxmox

```bash
ansible-playbook playbooks/03-cluster.yml
```

## 7. Ceph (mon, mgr, OSD, pool)

```bash
ansible-playbook playbooks/04-ceph.yml
```

2 OSD par nœud (`/dev/sdc`, `/dev/sdd`), pool `pa-pool` en réplication 3/2, rattaché
automatiquement au storage Proxmox.

---

# Vérifications avant de lancer

- Les MAC dans `ansible/inventory/production/host_vars/*.yml`
- Le plan d'adressage dans `docs/architecture/plan-adressage.md`
- Le vault (`vault_pve_root_password` bien défini)
- Docker disponible sur le control node (phase `00-prepare-install-media`)

---

# Évolutions prévues

- SDN / EVPN (Terraform `terraform/live/01-fabric`)
- Pool, capabilities, VM/LXC (Terraform `terraform/live/02-workloads`)
- Tooling (DNS, DHCP, IAM, NTP, Vault, Git, Observabilité, Bastion, Sauvegarde)
- Zero Trust (segmentation, ZTNA)
- Corosync sur son NIC dédié (tourne encore sur le réseau mgmt pour l'instant)
