# Image minimale portant proxmox-auto-install-assistant, pour les control
# nodes dont le glibc est trop ancien (ex. Debian 12 bookworm) pour installer
# le paquet nativement — l'outil est buildé pour trixie (glibc >= 2.39).
FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget ca-certificates gnupg xorriso \
    && wget -q https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg \
        -O /usr/share/keyrings/proxmox-archive-keyring.gpg \
    && printf 'Types: deb\nURIs: http://download.proxmox.com/debian/pve\nSuites: trixie\nComponents: pve-no-subscription\nSigned-By: /usr/share/keyrings/proxmox-archive-keyring.gpg\n' \
        > /etc/apt/sources.list.d/pve-install-repo.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends proxmox-auto-install-assistant \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["proxmox-auto-install-assistant"]
