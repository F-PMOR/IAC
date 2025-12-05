# Configuration du provider VMware vSphere
# Ce fichier ne contient que le provider, le bloc required_providers est dans provider.tf

provider "vsphere" {
  # Le provider lit automatiquement les variables d'environnement:
  # VSPHERE_USER, VSPHERE_PASSWORD, VSPHERE_SERVER
  # Pas besoin de les passer explicitement
  allow_unverified_ssl = var.vsphere_allow_unverified_ssl
}
