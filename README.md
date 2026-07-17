# Proxmox Infrastructure as Code

Déploiement complet d'une plateforme **Proxmox VE** hyperconvergée (3 nœuds,
ZFS, Ceph, SDN) en Infrastructure as Code : génération des médias
d'installation, formation du cluster, stockage Ceph, réseau SDN via
Terraform, puis (à venir) compute (VM/LXC), HA, tooling et Zero Trust.

Approche : tout en IaC, découpé en **phases numérotées**, chacune testable
indépendamment. Ansible pour la configuration système (installation,
cluster, réseau, Ceph, génération des credentials Terraform), Terraform
pour les ressources Proxmox déclaratives (SDN, pools, VM/LXC, HA).

---

## 1. Structure du projet

```text
.
├── ansible/
│   ├── ansible.cfg                        # inclut keepalive SSH pour les opérations longues
│   ├── collections/requirements.yml       # community.proxmox, ansible.posix, community.general
│   ├── inventory/production/
│   │   ├── hosts.yml                      # pve1/pve2/pve3 (IP mgmt)
│   │   ├── host_vars/                     # 5 MAC par nœud (mgmt, corosync, ceph_public, ceph_cluster, sdn_trunk)
│   │   └── group_vars/
│   │       ├── all/vars.yml               # domaine, clavier, disques boot, chemins partagés
│   │       ├── all/vault.yml              # chiffré (ansible-vault) - mot de passe root, jamais commité en clair
│   │       └── proxmox/main.yml           # cluster, Ceph, ISO, réseau, token Terraform
│   ├── playbooks/
│   │   ├── 00-generate-answer-files.yml   # génère les ANSWER_PVEx.TOML (Jinja + vault)
│   │   ├── 00-prepare-install-media.yml   # télécharge l'ISO PVE + génère les ISO auto-installables (via Docker)
│   │   ├── 01-repositories.yml            # dépôts Proxmox/Ceph, upgrade système
│   │   ├── 02-network.yml                 # interfaces dédiées ceph_public, ceph_cluster, corosync
│   │   ├── 03-cluster.yml                 # formation du cluster Proxmox
│   │   ├── 04-ceph.yml                    # mon/mgr/OSD/pool Ceph
│   │   └── 05-terraform-token.yml         # rôle/user/token Proxmox pour Terraform (moindre privilège)
│   └── roles/
│       ├── pve_answer_file/               # phase 00
│       ├── pve_install_media/             # phase 00 (ISO, via conteneur Docker debian:trixie)
│       ├── pve_repositories/              # phase 01
│       ├── pve_network/                   # phase 02
│       ├── pve_cluster/                   # phase 03
│       ├── pve_ceph/                      # phase 04
│       └── pve_terraform_token/           # phase 05
├── terraform/
│   ├── modules/
│   │   ├── pool/                          # pool de ressources Proxmox
│   │   ├── sdn_vlan/                      # zone SDN + VNets/Subnets
│   │   ├── capabilities/                  # rôles + ACL + groupe pour les opérateurs (pool-scoped)
│   │   ├── lxc/                           # conteneurs LXC (cloud-init, SSH key auto-générée)
│   │   ├── vm/                            # VM QEMU (clone de template, cloud-init)
│   │   └── ha/                            # groupes HA (node-affinity) + rattachement des ressources
│   └── live/
│       ├── 01-sdn/                        # ✅ testé et approuvé - SDN (LAN/SRV/DMZ/ADM/BCK/DEV)
│       ├── 02-compute/                    # pool, capabilities, LXC/VM - scaffold prêt, à peupler
│       ├── 03-ha/                         # groupes HA + ressources - scaffold prêt, pas encore testé
│       └── 04-zero-trust/                 # à venir
├── docs/
│   ├── architecture/plan-adressage.md     # plan IP complet (underlay 172.16.0.0/16 + VLAN SDN 10.0.0.0/16)
│   └── decisions/security-notes.md        # rotation du mot de passe root, gestion du vault
├── files/
│   ├── answer-files/                      # ANSWER_PVEx.TOML générés, gitignorés
│   ├── iso/                               # ISO PVE + ISO auto-installables, gitignorées
│   └── docker/pve-auto-install/           # image debian:trixie pour proxmox-auto-install-assistant
├── .env.terraform                         # généré par la phase 05, gitignoré (endpoint/insecure/token Proxmox)
└── README.md
```

---

## 2. Prérequis côté poste d'administration

- Linux ou WSL2, idéalement Debian/Ubuntu (le rôle `pve_install_media` installe un paquet système)
- **Docker** - `proxmox-auto-install-assistant` est buildé pour Debian trixie (glibc ≥ 2.39) et ne s'installe
  pas nativement sur un poste plus ancien (ex. Debian 12 bookworm/WSL) ; le rôle build une image dédiée et
  l'utilise en conteneur
- **Terraform** (ou OpenTofu) ≥ 1.14

```bash
pip install --break-system-packages ansible-core passlib proxmoxer requests
cd ansible
ansible-galaxy collection install -r collections/requirements.yml
```

---

## 3. Cloner le repo et vérifier l'inventaire

Avant de lancer quoi que ce soit, vérifie/adapte :
- `ansible/inventory/production/hosts.yml` - IP mgmt des 3 nœuds
- `ansible/inventory/production/host_vars/pve{1,2,3}.pa.lan.yml` - les 5 MAC par nœud
- `docs/architecture/plan-adressage.md` - le plan IP complet, à adapter si ton réseau diffère

---

## 4. Le mot de passe root (Ansible Vault)

```bash
cd ansible
ansible-vault create inventory/production/group_vars/all/vault.yml
# contenu : vault_pve_root_password: "un-mot-de-passe-fort"

echo "mot-de-passe-du-vault" > ../.vault_pass && chmod 600 ../.vault_pass
```

## 5. Ordre d'exécution complet

### 5.1. Phase 00 - Générer les `answer.toml`

```bash
ansible-playbook playbooks/00-generate-answer-files.yml
```

### 5.2. Phase 00 - Télécharger l'ISO et générer les médias d'installation

```bash
ansible-playbook playbooks/00-prepare-install-media.yml
```

Télécharge `proxmox-ve_9.2-1.iso` (checksum vérifié), build l'image Docker `pa-pve-auto-install`, génère
`files/iso/proxmox-ve-pve{1,2,3}.iso`. Supprime l'ISO correspondante avant de relancer pour forcer une
regénération après modification d'un `answer.toml`.

### 5.3. Installer les 3 serveurs physiquement

Graver/monter chaque ISO sur son serveur, démarrer dessus (installation 100% automatique). Puis déployer
l'accès SSH :

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

```bash
ssh-copy-id root@172.16.255.11
ssh-copy-id root@172.16.255.12
ssh-copy-id root@172.16.255.13
ansible proxmox -m ping
```

### 5.4. Phase 01 - Dépôts et mise à jour système

```bash
ansible-playbook playbooks/01-repositories.yml
```

### 5.5. Phase 02 - Interfaces réseau dédiées (Ceph + corosync)

```bash
ansible-playbook playbooks/02-network.yml
```

Configure `ceph_public` (172.16.253.0/24), `ceph_cluster` (172.16.252.0/24) et `corosync` (172.16.254.0/24)
sur les NIC dédiées.

### 5.6. Phase 03 - Cluster Proxmox

```bash
ansible-playbook playbooks/03-cluster.yml --vault-password-file ../.vault_pass
```

### 5.7. Phase 04 - Ceph (mon, mgr, OSD, pool)

```bash
ansible-playbook playbooks/04-ceph.yml
```

2 OSD par nœud (`/dev/sdc`, `/dev/sdd`), pool `pa-pool` en réplication 3/2.

### 5.8. Phase 05 - Token API pour Terraform

```bash
ansible-playbook playbooks/05-terraform-token.yml
```

Crée un rôle Proxmox à privilèges minimaux (`TerraformProvisioner`), un utilisateur `terraform@pve` dédié,
et son token API. Écrit `.env.terraform` à la racine du repo (gitignoré) :

```bash
export PROXMOX_VE_ENDPOINT="https://172.16.255.11:8006/"
export PROXMOX_VE_INSECURE="true"
export PROXMOX_VE_API_TOKEN="terraform@pve!terraform=<secret>"
```

⚠️ Le secret d'un token Proxmox n'est affiché **qu'une seule fois** à sa création. Si le token existe déjà
et que `.env.terraform` a été perdu, il faut le supprimer puis relancer le playbook :

```bash
ssh root@172.16.255.11 "pveum user token remove terraform@pve terraform"
ansible-playbook playbooks/05-terraform-token.yml
```

---

## 6. Terraform

Toutes les variables de connexion (`endpoint`, `insecure`, `api_token`) viennent de l'environnement
(`PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_INSECURE`, `PROXMOX_VE_API_TOKEN`, nativement supportées par le
provider `bpg/proxmox`) - aucun `.tfvars` à gérer pour la connexion. Source `.env.terraform` avant toute
commande :

```bash
source .env.terraform
```

### 6.1. `terraform/live/01-sdn` ✅ testé et approuvé

```bash
cd terraform/live/01-sdn
terraform init
terraform plan
terraform apply
```

Crée la zone SDN et les 6 VLAN (LAN, SRV, DMZ, ADM, BCK, DEV) définis dans `variables.tf`
(`var.sdn_zone`). Vérifie dans l'UI Proxmox (Datacenter → SDN) que les VNets apparaissent.

### 6.2. `terraform/live/02-compute`

```bash
cd ../02-compute
terraform init
terraform plan   # pool + capabilities uniquement tant que var.lxcs/var.vms sont vides
terraform apply
```

Remplir `var.lxcs`/`var.vms` (via un `terraform.tfvars` local, gitignoré) pour créer les premiers
services.

### 6.3. `terraform/live/03-ha`

À tester une fois `02-compute` peuplé d'au moins une ressource réelle (lit son state via
`terraform_remote_state`) :

```bash
cd ../03-ha
terraform init
terraform plan
```

Node-affinity uniquement pour l'instant (`proxmox_hagroup` + `proxmox_haresource`) - le resource-affinity
(co-location/anti-affinité) fait partie des "HA Rules" PVE 9, pas encore supportées par le provider
`bpg/proxmox` ([issue #2097](https://github.com/bpg/terraform-provider-proxmox/issues/2097)).

---

## 7. Résumé - ordre des commandes

```bash
cd ansible
ansible-vault create inventory/production/group_vars/all/vault.yml
echo "mot-de-passe-du-vault" > ../.vault_pass && chmod 600 ../.vault_pass

ansible-playbook playbooks/00-generate-answer-files.yml --vault-password-file ../.vault_pass
ansible-playbook playbooks/00-prepare-install-media.yml --vault-password-file ../.vault_pass
# -> installer les 3 serveurs physiquement, puis ssh-copy-id sur chacun
ansible proxmox -m ping

ansible-playbook playbooks/01-repositories.yml
ansible-playbook playbooks/02-network.yml
ansible-playbook playbooks/03-cluster.yml --vault-password-file ../.vault_pass
ansible-playbook playbooks/04-ceph.yml
ansible-playbook playbooks/05-terraform-token.yml

cd ..
source .env.terraform
cd terraform/live/01-sdn && terraform init && terraform apply
cd ../02-compute && terraform init && terraform apply
cd ../03-ha && terraform init && terraform apply
```

---

## 8. Vérifications finales

```bash
ssh root@172.16.255.11 pvecm status   # 3 nœuds dans le cluster
ssh root@172.16.255.11 ceph -s        # HEALTH_OK, 3 mon, 3 mgr, 6 OSD up/in
```

## 9. Évolutions prévues

- Peupler `terraform/live/02-compute` avec les premiers services (VM/LXC)
- Tester et valider `terraform/live/03-ha`
- Zero Trust (`terraform/live/04-zero-trust`)
- Tooling (DNS, DHCP, IAM, NTP, Vault, Git, Observabilité, Bastion, Sauvegarde)
- Resource-affinity HA dès que le provider `bpg/proxmox` le supportera
