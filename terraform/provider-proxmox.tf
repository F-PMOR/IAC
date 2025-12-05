terraform {
    required_version = "> 1.6.0"
    required_providers {
        proxmox = {
            source  = "bpg/proxmox"
            version = "0.64.0"
        }
        vsphere = {
            source  = "hashicorp/vsphere"
            version = "~> 2.6"
        }
    }
}

provider "proxmox" {
    # Le provider lit automatiquement les variables d'environnement:
    # PROXMOX_VE_ENDPOINT, PROXMOX_VE_USERNAME, PROXMOX_VE_PASSWORD
    # Pas besoin de les passer explicitement
    insecure = var.pve_insecure
}
