# Notes de sécurité

## Hash de mot de passe root exposé (à traiter avant de continuer)

Les fichiers `ANSWER_PVE1/2/3.TOML` contenaient un `root-password-hashed` (SHA-512-crypt)
identique sur les 3 nœuds, commité sur un repo **public**, présent dans l'historique git.

Un hash de ce type reste attaquable hors-ligne (brute-force/dictionnaire selon la
complexité du mot de passe). Actions recommandées, par ordre de priorité :

1. **Changer le mot de passe root sur les 3 nœuds PVE dès que possible** (même s'il n'a
   probablement pas fuité au-delà de ce hash, il faut considérer qu'il est compromis).
2. Ne plus jamais committer de fichier `answer.toml` réel — ils sont désormais générés
   dans `files/answer-files/` (gitignoré), à partir du rôle Ansible `pve_answer_file`
   (phase 00) qui lira le mot de passe depuis `ansible/inventory/production/group_vars/all/vault.yml`
   (chiffré avec `ansible-vault`).
3. Optionnel mais recommandé pour un repo public : purger le hash de l'historique git
   avec `git filter-repo` (ou BFG Repo-Cleaner) une fois le mot de passe changé — ça ne
   sert à rien avant l'étape 1, et ça réécrit l'historique (force-push, à faire seul sur
   le repo, en prévenant si quelqu'un d'autre a cloné).
