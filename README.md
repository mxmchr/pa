# Proxmox Infrastructure as Code

Ce dépôt permet d'automatiser le déploiement d'une infrastructure **Proxmox VE** à l'aide d'Ansible.

L'objectif est de :

- Déployer automatiquement trois nœuds Proxmox via les fichiers `answer.toml`
- Préparer des ISO d'installation personnalisées
- Configurer les dépôts Proxmox
- Installer les dépendances Python
- Créer automatiquement un cluster Proxmox

---

# Structure du projet

```text
.
├── ansible/
│   ├── collections/
│   ├── inventory/production/
│   ├── playbooks/
│   │   ├── 01-repositories.yml
│   │   └── 03-cluster.yml   # 02-network.yml et 00-generate-answer-files.yml à venir
│   ├── roles/
│   │   ├── pve_cluster/
│   │   └── pve_repositories/
│   └── ansible.cfg
├── terraform/
│   ├── modules/              # pool, sdn_vlan, capabilities, lxc, vm
│   └── live/
│       ├── 01-fabric/        # zones SDN / VLAN (state isolé)
│       └── 02-workloads/     # pool, capabilities, LXC/VM (state isolé)
├── docs/
│   ├── architecture/plan-adressage.md
│   └── decisions/security-notes.md
├── files/answer-files/       # ANSWER_PVE*.TOML générés, gitignorés (voir security-notes.md)
└── README.md
```

> Cette structure remplace l'ancienne arborescence `IaC/Ansible/Proxmox/...` et
> `IaC/Terraform/Build/...` (branche `restructure/iac-phases`). Voir
> `docs/decisions/security-notes.md` avant toute chose : un mot de passe root a
> été committé en clair (hashé) et doit être changé.

---

# Prérequis

- 3 serveurs physiques
- Un poste d'administration avec Ansible
- Accès SSH aux trois nœuds
- Python 3
- Ansible

Installation d'Ansible :

```bash
python3 -m venv venv
source venv/bin/activate

pip install ansible
ansible-galaxy collection install community.general community.proxmox
```

---

# Téléchargement de Proxmox VE

Télécharger l'image officielle :

```bash
wget https://enterprise.proxmox.com/iso/proxmox-ve_9.2-1.iso
```

---

# Configuration des fichiers Answer

Modifier les trois fichiers dans `files/answer-files/` (copier `ANSWER_PVE.toml.example` en `ANSWER_PVE1.TOML`, `ANSWER_PVE2.TOML`, `ANSWER_PVE3.TOML` — ces fichiers contiennent un secret et sont gitignorés, voir `docs/decisions/security-notes.md`) :

- `ANSWER_PVE1.TOML`
- `ANSWER_PVE2.TOML`
- `ANSWER_PVE3.TOML`

Adapter notamment :

- le hostname
- l'adresse IP
- la passerelle
- le DNS
- le mot de passe root
- le disque d'installation
- les paramètres réseau

Chaque serveur doit posséder son propre fichier `ANSWER_PVEX.TOML`.

---

# Préparation des ISO

Installer l'outil Proxmox permettant de générer une ISO d'installation automatique :

```bash
apt install proxmox-auto-install-assistant
```

Puis générer une ISO pour chaque serveur.

## Exemple

```bash
proxmox-auto-install-assistant prepare-iso \
    proxmox-ve_9.2-1.iso \
    --fetch-from iso \
    --answer-file files/answer-files/ANSWER_PVE1.TOML \
    --output proxmox-ve-pve1.iso
```

Cette commande est celle recommandée par la documentation officielle Proxmox pour intégrer directement le fichier `answer.toml` dans l'ISO.

À l'issue de cette étape, vous disposez de trois ISO prêtes à être utilisées :

- `proxmox-ve-pve1.iso`
- `proxmox-ve-pve2.iso`
- `proxmox-ve-pve3.iso`

Il ne reste plus qu'à démarrer chaque serveur sur son ISO correspondante.

---

# Déploiement Ansible

Une fois les trois serveurs installés et accessibles en SSH :

```bash
cd ansible
```

---

# Étape 1 : Configuration des dépôts

Configure les dépôts Proxmox et installe les dépendances nécessaires.

```bash
ansible-playbook playbooks/01-repositories.yml
```

Cette étape :

- configure les dépôts Proxmox
- installe les dépendances Python
- installe la bibliothèque Python utilisée par les modules Ansible Proxmox

---

# Étape 2 : Création du cluster

Créer automatiquement le cluster :

```bash
ansible-playbook playbooks/03-cluster.yml
```

Ce playbook :

- crée le cluster
- ajoute les nœuds
- vérifie le bon fonctionnement du cluster

---

# Vérifications

Avant d'exécuter les playbooks, vérifier :

- les adresses IP dans l'inventaire Ansible
- les accès SSH
- les clés SSH ou mots de passe
- les fichiers `ANSWER_PVE*.TOML`

---

# Ordre d'exécution

1. Télécharger l'ISO Proxmox.
2. Modifier les fichiers :
   - `ANSWER_PVE1.TOML`
   - `ANSWER_PVE2.TOML`
   - `ANSWER_PVE3.TOML`
3. Générer les trois ISO automatiques.
4. Installer les trois serveurs Proxmox.
5. Vérifier l'accès SSH.
6. Exécuter :

```bash
ansible-playbook playbooks/01-repositories.yml
```

7. Puis :

```bash
ansible-playbook playbooks/03-cluster.yml
```

Le cluster Proxmox est alors entièrement déployé et opérationnel.

---

# Évolutions prévues

- Déploiement PXE
- Configuration automatique du stockage
- Déploiement Ceph
- Configuration réseau avancée
- Gestion des certificats
- Création des utilisateurs
- Configuration des sauvegardes
```
