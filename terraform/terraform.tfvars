# PVE informations
# Les credentials (endpoint, username, password) sont lus depuis les variables d'environnement:
# - PROXMOX_VE_ENDPOINT
# - PROXMOX_VE_USERNAME  
# - PROXMOX_VE_PASSWORD
# Ces variables sont définies dans .env.secrets

pve_node     = "pve01"
pve_insecure = true

# Debian images
debian_image_url      = "https://cloud.debian.org/images/cloud/bookworm/20241004-1890/debian-12-generic-amd64-20241004-1890.qcow2"
debian_image_checksum = "8ded46aa96fefbe67ad752efc59dea3a4ce7a24208c8c7bdf8396cd722762b81fe8536f2ec0050255d5197b2396e32eb380167ac1999617cfcd3ac1c15e74e3f"
