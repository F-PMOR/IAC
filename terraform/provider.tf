terraform {
    required_version = "> 1.6.0"
    required_providers {
        proxmox = {
            source  = "bpg/proxmox"
            version = "0.64.0"
        }
    }
}

provider "proxmox" {
    endpoint    = var.pve_endpoint
    username    = var.pve_username
    password    = var.pve_password
    insecure    = var.pve_insecure
}
