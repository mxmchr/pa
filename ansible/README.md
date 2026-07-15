# Proxmox Infrastructure as Code

Déploiement complet d'une plateforme **Proxmox VE** hyperconvergée (3 nœuds,
ZFS, Ceph, SDN à venir) en Infrastructure as Code : génération des médias
d'installation, formation du cluster, stockage Ceph, puis (à venir) réseau
SDN/EVPN via Terraform, tooling et Zero Trust.

Approche : tout en IaC, découpé en **phases numérotées**, chacune testable
indépendamment. Ansible pour la configuration système (installation, cluster,
réseau, Ceph, tooling), Terraform pour les ressources Proxmox déclaratives
(SDN, pools, VM/LXC).

---

## 1. Prérequis côté poste d'administration

Le poste qui exécute Ansible/Terraform (ton laptop, une VM, un WSL...).

### Système
- Linux ou WSL2 sur une distribution **Debian/Ubuntu** (le rôle `pve_install_media`
  installe un paquet système ; d'autres OS demanderaient d'adapter ce rôle)
- **Docker** — indispensable dès la phase 00 : `proxmox-auto-install-assistant`
  est buildé pour Debian **trixie** (glibc ≥ 2.39) et ne s'installe pas
  nativement sur un poste plus ancien (ex. Debian 12 bookworm/WSL). Le rôle
  build une image `debian:trixie` dédiée et l'utilise en conteneur — vérifie
  juste que `docker version` répond.
- Git

### Paquets Python / Ansible
```bash
pip install --break-system-packages ansible-core passlib proxmoxer requests
```

### Collections Ansible
```bash
cd ansible
ansible-galaxy collection install -r collections/requirements.yml
```
(installe `community.proxmox`, `community.general`, `ansible.posix`)

### Accès réseau requis depuis ce poste
- Vers `enterprise.proxmox.com` et `download.proxmox.com` (ISO + dépôts)
- Vers le port SSH (22) et l'API Proxmox (TCP 8006) des 3 futurs nœuds

---

## 2. Cloner le repo et vérifier l'inventaire

```bash
git clone <url-du-repo> pa
cd pa/ansible
```

Vérifie/adapte avant de lancer quoi que ce soit :
- `inventory/production/hosts.yml` — IP mgmt des 3 nœuds
- `inventory/production/host_vars/pve{1,2,3}.pa.lan.yml` — les 5 MAC par nœud
  (mgmt, corosync, ceph_public, ceph_cluster, sdn_trunk)
- `docs/architecture/plan-adressage.md` — le plan IP complet, à adapter si ton
  réseau diffère du nôtre (172.16.0.0/16 underlay, 10.0.0.0/16 VLAN SDN)

---

## 3. Créer le vault (mot de passe root)

Le mot de passe root des 3 nœuds n'est **jamais** stocké en clair dans le
repo. Il vit chiffré dans `group_vars/all/vault.yml` :

```bash
ansible-vault create inventory/production/group_vars/all/vault.yml
```

Ça ouvre ton éditeur — colle ceci (remplace par un vrai mot de passe fort) :
```yaml
vault_pve_root_password: "un-mot-de-passe-fort"
```

Ansible te redemandera le mot de passe **du vault** (différent du mot de
passe root !) à chaque commande touchant à ce fichier. Deux façons de le
fournir :
```bash
# interactif, à chaque commande
--ask-vault-pass

# ou via un fichier local jamais commité (déjà dans .gitignore)
echo "mot-de-passe-du-vault" > ../.vault_pass && chmod 600 ../.vault_pass
--vault-password-file ../.vault_pass
```
Tous les exemples ci-dessous utilisent la seconde forme.

⚠️ Un mot de passe avait été committé (hashé) sur ce repo avant sa
réorganisation — voir `docs/decisions/security-notes.md`.

---

## 4. Phase 00 — Générer les `answer.toml`

```bash
ansible-playbook playbooks/00-generate-answer-files.yml --vault-password-file ../.vault_pass
```

Produit `files/answer-files/ANSWER_PVE{1,2,3}.TOML` (Jinja + hash du mot de
passe recalculé à chaque run depuis le vault — normal que cette ligne
change d'un run à l'autre).

---

## 5. Phase 00 — Télécharger l'ISO et générer les médias d'installation

```bash
ansible-playbook playbooks/00-prepare-install-media.yml --vault-password-file ../.vault_pass
```

- Télécharge `proxmox-ve_9.2-1.iso` (checksum SHA256 vérifié)
- Build l'image Docker `pa-pve-auto-install` (une fois, ~1-2 min)
- Génère `files/iso/proxmox-ve-pve{1,2,3}.iso`, chacune avec son answer.toml intégré

Pour forcer une regénération (après modification d'un answer.toml), supprime
l'ISO correspondante avant de relancer (le rôle ne réécrit pas si le fichier existe déjà).

---

## 6. Installer les 3 serveurs physiquement

Graver/monter chaque `proxmox-ve-pveX.iso` sur son serveur, démarrer dessus
(installation 100% automatique, aucune interaction). Vérifie ensuite qu'ils
répondent sur leur IP mgmt (`172.16.255.11/12/13` par défaut).

### Accès SSH pour Ansible

Les nœuds fraîchement installés n'ont pas ta clé SSH publique. Deux options :

**Option A — copier ta clé (recommandé, à faire une fois par nœud) :**
```bash
ssh-copy-id root@172.16.255.11
ssh-copy-id root@172.16.255.12
ssh-copy-id root@172.16.255.13
```

**Option B — mot de passe pour les premières commandes :**
ajoute `--ask-pass` à n'importe quelle commande `ansible-playbook` ci-dessous
tant que la clé n'est pas déployée.

Vérifie la connectivité avant de continuer :
```bash
ansible proxmox -m ping
```

---

## 7. Phase 01 — Dépôts et mise à jour système

```bash
ansible-playbook playbooks/01-repositories.yml
```

Bascule les dépôts enterprise → no-subscription (PVE + Ceph Tentacle) et fait
un `apt full-upgrade`. Pas besoin du vault ici.

⚠️ **Piège connu** : `apt-listchanges` peut bloquer indéfiniment en essayant
d'envoyer un mail via Postfix (lui-même en cours de mise à jour). Le rôle le
désactive (`frontend=none`) avant l'upgrade — si tu vois `rc: -9` sur cette
tâche malgré tout, vérifie qu'aucun process `apt`/`dpkg` ne traîne encore sur
le nœud (`ps aux | grep apt`) avant de relancer.

⚠️ Un nouveau noyau peut être installé — un reboot peut être nécessaire
(pas automatisé pour l'instant, `reboot` manuel si besoin).

Test recommandé : un nœud d'abord (`--limit pve1.pa.lan --check --diff`),
puis exécution réelle, avant d'étendre aux 3.

---

## 8. Phase 02 — Interfaces réseau dédiées à Ceph

```bash
ansible-playbook playbooks/02-network.yml
```

Configure `ceph_public` (172.16.253.0/24) et `ceph_cluster` (172.16.252.0/24)
sur les NIC dédiées (nommage `enx<mac>`, cf. `host_vars`). Pas besoin du
vault. Le rôle valide lui-même (via `assert`) que les IP attendues sont bien
montées avant de continuer.

---

## 9. Phase 03 — Cluster Proxmox

```bash
ansible-playbook playbooks/03-cluster.yml --vault-password-file ../.vault_pass
```

Passe par l'API Proxmox (`community.proxmox.proxmox_cluster`, appelé depuis
le poste d'admin — d'où le besoin de `proxmoxer`/`requests` en Python).
`serial: 1` déjà dans le playbook : pve1 crée le cluster, pve2 et pve3
rejoignent un par un, avec une pause de 20s après chaque étape.

Recommandé : `--limit pve1.pa.lan` d'abord, vérifier `pvecm status`, puis
étendre.

---

## 10. Phase 04 — Ceph (mon, mgr, OSD, pool)

```bash
ansible-playbook playbooks/04-ceph.yml
```

- 2 OSD par nœud (`/dev/sdc`, `/dev/sdd`), pool `pa-pool` en réplication 3/2,
  rattaché automatiquement au storage Proxmox
- Réseau public `172.16.253.0/24`, réseau cluster/replication `172.16.252.0/24`
- Pas besoin du vault

⚠️ **Piège connu** : `pveceph install` n'a pas de mode non-interactif et
demande une confirmation `(y/N)` — via Ansible (sans tty), ça part sur `N`
sans erreur visible. Le rôle installe donc les paquets Ceph directement via
`apt` (`ceph`, `ceph-mon`, `ceph-mgr`, `ceph-osd`, etc.) plutôt que
`pveceph install`, ce qui est réellement idempotent.

⚠️ Le dépôt Ceph configuré en phase 01 pointe vers **Tentacle (20.2)**, la
version par défaut sur les installations neuves PVE 9.2 (Squid 19.x reste
disponible mais n'est plus le défaut). Les 3 nœuds doivent avoir la **même**
version de Ceph, sinon les moniteurs ne formeront pas de quorum.

Recommandé : `--limit pve1.pa.lan` d'abord (`ceph -s` doit passer en
`HEALTH_WARN`, normal avec 1 seul mon), puis étendre à pve2/pve3
(`HEALTH_OK` attendu une fois les 3 réunis).

---

## Résumé — ordre des commandes

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
```

---

## Vérifications finales

```bash
ssh root@172.16.255.11 pvecm status   # 3 nœuds dans le cluster
ssh root@172.16.255.11 ceph -s        # HEALTH_OK, 3 mon, 3 mgr, 6 OSD up/in
```

---

## Structure du projet

```text
.
├── ansible/
│   ├── ansible.cfg                    # inclut keepalive SSH pour les opérations longues
│   ├── collections/requirements.yml
│   ├── inventory/production/
│   │   ├── hosts.yml                  # pve1/pve2/pve3
│   │   ├── host_vars/                 # MAC par nœud
│   │   └── group_vars/
│   │       ├── all/vars.yml
│   │       ├── all/vault.yml          # chiffré, jamais commité en clair
│   │       └── proxmox/main.yml       # cluster, Ceph, ISO, réseau
│   ├── playbooks/                     # 00 à 04, voir sections ci-dessus
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
│       ├── 01-fabric/                 # SDN (LAN/SRV/DMZ/ADM/BCK/DEV) — à venir
│       ├── 02-workloads/              # pool, capabilities, LXC/VM — à venir
│       └── 03-zero-trust/             # à venir
├── docs/
│   ├── architecture/plan-adressage.md
│   └── decisions/security-notes.md
├── files/
│   ├── answer-files/                  # gitignorés
│   ├── iso/                           # gitignorées
│   └── docker/pve-auto-install/
└── README.md
```

---

## Évolutions prévues

- SDN / EVPN (Terraform `terraform/live/01-fabric`)
- Pool, capabilities, VM/LXC (Terraform `terraform/live/02-workloads`)
- Tooling (DNS, DHCP, IAM, NTP, Vault, Git, Observabilité, Bastion, Sauvegarde)
- Zero Trust (segmentation, ZTNA)
- Corosync sur son NIC dédié (tourne encore sur le réseau mgmt pour l'instant)
