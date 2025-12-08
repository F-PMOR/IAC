provider "proxmox" {
  # Le provider lit automatiquement les variables d'environnement:
  # PROXMOX_VE_ENDPOINT, PROXMOX_VE_USERNAME, PROXMOX_VE_PASSWORD
  # Pas besoin de les passer explicitement
  insecure = var.pve_insecure
}
