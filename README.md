# Proxmox Infrastructure as Code

Ce dépôt automatise le déploiement complet d'une plateforme **Proxmox VE
hyperconvergée** :

- 3 nœuds Proxmox VE
- Installation automatisée via ISO auto-installables
- Configuration système avec Ansible
- Formation du cluster Proxmox
- Déploiement Ceph (MON/MGR/OSD/pools)
- Préparation du réseau SDN (à venir)
- Déploiement des ressources Proxmox via Terraform

L'objectif est d'avoir une infrastructure **entièrement reproductible**, où
chaque étape est automatisée et versionnée.

L'approche est découpée en **phases indépendantes et testables** :

- **Ansible** : installation, configuration système, cluster, réseau, Ceph,
  tooling
- **Terraform** : gestion déclarative des ressources Proxmox (SDN, pools,
  VM/LXC, capacités)

---

# Structure du projet

```text
.
├── ansible/
│   ├── ansible.cfg
│   ├── collections/requirements.yml
│   ├── inventory/production/
│   │   ├── hosts.yml                  # pve1/pve2/pve3
│   │   ├── host_vars/                 # MAC et paramètres spécifiques par nœud
│   │   └── group_vars/
│   │       ├── all/vars.yml           # variables globales
│   │       ├── all/vault.yml           # secrets chiffrés Ansible Vault
│   │       └── proxmox/main.yml       # paramètres Proxmox/Ceph/réseau
│   │
│   ├── playbooks/
│   │   ├── 00-generate-answer-files.yml
│   │   ├── 00-prepare-install-media.yml
│   │   ├── 01-repositories.yml
│   │   ├── 02-network.yml
│   │   ├── 03-cluster.yml
│   │   └── 04-ceph.yml
│   │
│   └── roles/
│       ├── pve_answer_file/
│       ├── pve_install_media/
│       ├── pve_repositories/
│       ├── pve_network/
│       ├── pve_cluster/
│       └── pve_ceph/
│
├── terraform/
│   ├── modules/
│   │   ├── pool/
│   │   ├── sdn_vlan/
│   │   ├── capabilities/
│   │   ├── lxc/
│   │   └── vm/
│   │
│   └── live/
│       ├── 01-fabric/
│       ├── 02-workloads/
│       └── 03-zero-trust/
│
├── docs/
│   ├── architecture/
│   │   └── plan-adressage.md
│   └── decisions/
│       └── security-notes.md
│
├── files/
│   ├── answer-files/                  # générés automatiquement
│   ├── iso/                           # ISO générées
│   └── docker/pve-auto-install/
│
└── README.md
```

---

# Prérequis

## Infrastructure cible

- 3 serveurs physiques Proxmox VE
- 5 interfaces réseau par serveur :

| Interface | Usage |
|---|---|
| mgmt | Administration Proxmox |
| corosync | Communication cluster |
| ceph_public | Réseau client Ceph |
| ceph_cluster | Réplication Ceph |
| sdn_trunk | Réseau SDN |

---

## Poste de contrôle Ansible

Un poste Linux (WSL accepté) avec :

- Python 3
- Ansible Core
- passlib
- Docker

Installation :

```bash
pip install ansible-core passlib
```

Installation des collections :

```bash
ansible-galaxy collection install -r ansible/collections/requirements.yml
```

Docker est nécessaire uniquement pour la génération des ISO :

`proxmox-auto-install-assistant` nécessite Debian Trixie
(glibc >= 2.39) et est exécuté dans un conteneur Docker afin de rester
compatible avec un control node plus ancien.

---

# Préparation SSH

Avant toute exécution Ansible, les clés SSH doivent être générées puis
déployées sur les nœuds Proxmox.

## Génération de la clé SSH dédiée

Sur le poste de contrôle :

```bash
ssh-keygen \
  -t ed25519 \
  -f ~/.ssh/proxmox_iac \
  -C "proxmox-iac"
```

Ne pas définir de passphrase si la clé doit être utilisée automatiquement
par Ansible.

---

## Installation de la clé sur les nœuds Proxmox

Copier la clé publique sur chaque serveur :

```bash
ssh-copy-id \
  -i ~/.ssh/proxmox_iac.pub \
  root@pve1

ssh-copy-id \
  -i ~/.ssh/proxmox_iac.pub \
  root@pve2

ssh-copy-id \
  -i ~/.ssh/proxmox_iac.pub \
  root@pve3
```

Tester :

```bash
ssh -i ~/.ssh/proxmox_iac root@pve1
ssh -i ~/.ssh/proxmox_iac root@pve2
ssh -i ~/.ssh/proxmox_iac root@pve3
```

La connexion SSH doit fonctionner sans demander de mot de passe avant de
lancer Ansible.

La clé utilisée peut être définie dans `ansible.cfg` :

```ini
[defaults]
private_key_file = ~/.ssh/proxmox_iac
```

---

# Gestion des secrets Ansible Vault

Les secrets ne sont jamais stockés en clair.

Le mot de passe root Proxmox est stocké dans :

```
ansible/inventory/production/group_vars/all/vault.yml
```

Création :

```bash
cd ansible

ansible-vault create \
inventory/production/group_vars/all/vault.yml
```

Contenu :

```yaml
vault_pve_root_password: "mot-de-passe-root"
```

Le fichier de mot de passe Vault utilisé localement doit être présent :

```
.vault_pass
```

Ce fichier est ignoré par Git.

Toutes les commandes Ansible sont configurées pour utiliser ce fichier.

---

# Ordre d'exécution

## 1. Génération des fichiers answer.toml

```bash
ansible-playbook playbooks/00-generate-answer-files.yml
```

Génère :

```
files/answer-files/ANSWER_PVE1.TOML
files/answer-files/ANSWER_PVE2.TOML
files/answer-files/ANSWER_PVE3.TOML
```

Les fichiers sont générés à partir :

- des templates Jinja
- des variables d'inventaire
- du vault Ansible

Le hash du mot de passe root est recalculé automatiquement.

---

## 2. Génération des ISO Proxmox auto-installables

```bash
ansible-playbook playbooks/00-prepare-install-media.yml
```

Cette étape :

- télécharge l'ISO Proxmox VE
- vérifie son checksum
- construit l'environnement Docker nécessaire
- injecte les fichiers answer

Résultat :

```
files/iso/

├── proxmox-ve-pve1.iso
├── proxmox-ve-pve2.iso
└── proxmox-ve-pve3.iso
```

---

## 3. Installation des serveurs

Démarrer chaque serveur avec son ISO correspondant.

L'installation est entièrement automatique :

- partitionnement
- configuration réseau
- création utilisateur root
- installation Proxmox VE

---

## 4. Dépôts et mises à jour

```bash
ansible-playbook playbooks/01-repositories.yml
```

Configure :

- repositories Proxmox
- repositories Ceph
- mises à jour système

---

## 5. Configuration réseau Ceph

```bash
ansible-playbook playbooks/02-network.yml
```

Configure :

- `ceph_public`
- `ceph_cluster`

Exemple :

```
ceph_public  : 172.16.253.0/24
ceph_cluster : 172.16.252.0/24
```

Le plan complet est disponible dans :

```
docs/architecture/plan-adressage.md
```

---

## 6. Création du cluster Proxmox

```bash
ansible-playbook playbooks/03-cluster.yml
```

Création :

```
pve1
 |
 +-- pve2
 |
 +-- pve3
```

---

## 7. Déploiement Ceph

```bash
ansible-playbook playbooks/04-ceph.yml
```

Déploie :

- MON
- MGR
- OSD
- pools

Configuration actuelle :

- 2 OSD par nœud
- disques :
  - `/dev/sdc`
  - `/dev/sdd`

Pool :

```
pa-pool
```

Réplication :

```
size = 3
min_size = 2
```

Le stockage est automatiquement ajouté à Proxmox.

---

# Vérifications avant exécution

Vérifier :

- [ ] Les clés SSH fonctionnent vers les 3 nœuds
- [ ] Les MAC sont renseignées dans :
  
```
ansible/inventory/production/host_vars/
```

- [ ] Le plan réseau est validé :

```
docs/architecture/plan-adressage.md
```

- [ ] Le vault contient :

```
vault_pve_root_password
```

- [ ] Docker est disponible pour la génération ISO

---

# Évolutions prévues

## Réseau

- SDN Proxmox
- VLAN
- EVPN
- Micro-segmentation
- Routage dynamique

Terraform :

```
terraform/live/01-fabric
```

---

## Workloads

Terraform :

```
terraform/live/02-workloads
```

Prévu :

- pools Proxmox
- capabilities
- VM
- LXC
- templates

---

## Services d'infrastructure

Déploiement automatisé :

- DNS
- DHCP
- IAM
- NTP
- Vault
- Git
- Observabilité
- Bastion
- Sauvegarde

---

## Zero Trust

Prévu :

- segmentation réseau
- contrôle d'accès
- ZTNA
- politiques d'accès dynamiques

---

# Notes techniques

- Corosync utilise actuellement le réseau management.
- Un réseau dédié corosync est prévu dans une prochaine évolution.
- La microsegmentation sera réalisée via SDN Proxmox et règles réseau
  déclaratives.
- L'objectif final est une plateforme Proxmox entièrement reconstruisible
  depuis le dépôt Git.
