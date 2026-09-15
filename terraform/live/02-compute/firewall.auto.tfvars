############################################
### Règles de filtrage des workloads      ###
############################################
# Politique d'entrée en rejet : tout flux absent de ces groupes est coupé.
#
# Passer firewall_enabled à true seulement après avoir vérifié chaque
# groupe sur un workload isolé.

firewall_enabled = false

firewall_security_groups = {

  # Commun à tous les workloads : administration et supervision.
  pa-base = {
    comment = "Administration et supervision"
    rules = [
      { proto = "tcp", dport = "22", source = "172.16.255.0/24", comment = "SSH depuis l'administration" },
      { proto = "tcp", dport = "22", source = "10.0.40.0/24", comment = "SSH depuis le segment ADM" },
      { proto = "icmp", source = "172.16.255.0/24", comment = "ICMP depuis l'administration" },
      { proto = "icmp", source = "10.0.0.0/16", comment = "ICMP interne, diagnostic" },
      { proto = "tcp", dport = "9100", source = "10.0.40.0/24", comment = "Collecte de metriques" },
    ]
  }

  # Résolveurs de noms.
  pa-dns = {
    comment = "Resolution de noms"
    rules = [
      { proto = "udp", dport = "53", source = "10.0.0.0/16", comment = "DNS UDP" },
      { proto = "tcp", dport = "53", source = "10.0.0.0/16", comment = "DNS TCP, transferts et reponses longues" },
    ]
  }

  # Point d'entrée applicatif.
  pa-proxy = {
    comment = "Point d'entree applicatif"
    rules = [
      { proto = "tcp", dport = "80", source = "10.0.0.0/16", comment = "HTTP, redirige vers HTTPS" },
      { proto = "tcp", dport = "443", source = "10.0.0.0/16", comment = "HTTPS" },
    ]
  }

  # Applications publiées derrière le point d'entrée.
  # Seul le proxy les joint : personne d'autre n'a de raison de le faire.
  pa-backend = {
    comment = "Applications derriere le proxy"
    rules = [
      { proto = "tcp", dport = "9000", source = "10.0.20.20", comment = "Authentik depuis le proxy" },
      { proto = "tcp", dport = "3000", source = "10.0.20.20", comment = "Supervision depuis le proxy" },
    ]
  }

  # Coffre à secrets et autorité de certification.
  pa-vault = {
    comment = "Coffre a secrets"
    rules = [
      { proto = "tcp", dport = "8200", source = "10.0.20.0/24", comment = "API depuis le segment SRV" },
      { proto = "tcp", dport = "8200", source = "10.0.30.0/24", comment = "API depuis la DMZ, emission de certificats" },
      { proto = "tcp", dport = "8200", source = "172.16.255.0/24", comment = "API depuis l'administration" },
    ]
  }

  # Accès distant, seul service joignable depuis l'extérieur.
  pa-vpn = {
    comment = "Acces distant Zero Trust"
    rules = [
      { proto = "tcp", dport = "80", comment = "HTTP, redirige vers HTTPS" },
      { proto = "tcp", dport = "443", comment = "Tableau de bord et plan de controle" },
      { proto = "udp", dport = "3478", comment = "Relais de medias" },
      { proto = "udp", dport = "49152:49200", comment = "Plage du relais de medias" },
      { proto = "tcp", dport = "33080", comment = "Relais chiffre" },
    ]
  }

  # Sauvegarde : seuls les nœuds déposent des sauvegardes.
  pa-backup = {
    comment = "Serveur de sauvegarde"
    rules = [
      { proto = "tcp", dport = "8007", source = "172.16.255.0/24", comment = "API depuis les noeuds" },
      { proto = "tcp", dport = "8007", source = "10.0.40.0/24", comment = "Interface depuis le segment ADM" },
    ]
  }

  # Groupe de diagnostic, à n'appliquer que temporairement.
  pa-debug = {
    comment = "Diagnostic temporaire, journalise tout"
    rules = [
      { action = "ACCEPT", proto = "tcp", source = "10.0.0.0/16", log = "info", comment = "Tout TCP interne, journalise" },
    ]
  }
}

firewall_workload_groups = {
  pdns1     = ["pa-base", "pa-dns"]
  pdns2     = ["pa-base", "pa-dns"]
  openbao   = ["pa-base", "pa-vault"]
  traefik   = ["pa-base", "pa-proxy"]
  authentik = ["pa-base", "pa-backend"]
  netbird   = ["pa-base", "pa-vpn"]
  pbs       = ["pa-base", "pa-backup"]
}