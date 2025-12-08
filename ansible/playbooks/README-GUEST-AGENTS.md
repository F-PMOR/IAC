# Installation des Guest Agents

Ce projet supporte deux types de guest agents selon le provider d'infrastructure utilisé :

## 1. QEMU Guest Agent (pour Proxmox)

### Installation automatique via Cloud-init
Les VMs Proxmox sont configurées pour installer automatiquement le QEMU Guest Agent au premier démarrage via le fichier `cloudinit/vendor-config-proxmox.yaml`.

### Installation manuelle via Ansible
Si vous avez des VMs existantes sans le guest agent :

```bash
# Toutes les VMs Proxmox
./scripts/deploy-ansible.sh --tags qemu-agent

# Une VM spécifique
./scripts/deploy-ansible.sh --tags qemu-agent --limit mysql-prod01
```

### Pourquoi c'est nécessaire ?
Le provider Terraform `bpg/proxmox` requiert le QEMU Guest Agent pour :
- Obtenir les informations réseau (IP, MAC, interfaces)
- Effectuer un refresh d'état sans timeout
- Gérer proprement les arrêts/redémarrages

**Symptôme sans agent :** `terraform plan` ou `terraform import` reste bloqué indéfiniment, avec des erreurs HTTP 500 dans les logs debug :
```
QEMU guest agent is not running
```

## 2. VMware Tools (pour vSphere)

### Installation automatique via Cloud-init
Les VMs VMware sont configurées pour installer automatiquement `open-vm-tools` au premier démarrage via le fichier `cloudinit/vendor-config-vmware.yaml`.

### Installation manuelle via Ansible
Si vous avez des VMs existantes sans VMware Tools :

```bash
# Toutes les VMs VMware
./scripts/deploy-ansible.sh --tags vmware-tools

# Une VM spécifique
./scripts/deploy-ansible.sh --tags vmware-tools --limit app-vm01
```

### Pourquoi c'est nécessaire ?
Le provider Terraform `hashicorp/vsphere` requiert VMware Tools pour :
- Obtenir les informations réseau de la VM
- Attendre que la VM soit prête après provisioning
- Gérer l'état de la VM (power on/off)
- Synchroniser l'heure système

**Note :** `open-vm-tools` est la version open-source recommandée par VMware depuis vSphere 6.5+.

## 3. Installation des deux agents

Si vous avez un environnement mixte Proxmox + VMware :

```bash
# Installer tous les agents (Proxmox et VMware)
./scripts/deploy-ansible.sh --tags agent

# Vérifier que tout fonctionne
ansible all -i ansible/inventory/proxmox/inventory.ini -m ping
```

## 4. Vérification

### QEMU Guest Agent (Proxmox)
```bash
# Sur la VM
systemctl status qemu-guest-agent

# Depuis Proxmox CLI
qm guest cmd <vmid> network-get-interfaces
```

### VMware Tools (vSphere)
```bash
# Sur la VM
vmware-toolbox-cmd -v
systemctl status vmtoolsd

# Depuis vSphere CLI ou GUI
# L'icône VMware Tools doit être verte dans la console
```

## 5. Troubleshooting

### QEMU Guest Agent ne démarre pas
```bash
# Vérifier les logs
journalctl -u qemu-guest-agent -n 50

# Réinstaller
apt remove --purge qemu-guest-agent
apt update && apt install qemu-guest-agent
systemctl enable --now qemu-guest-agent
```

### VMware Tools ne fonctionnent pas
```bash
# Vérifier les logs
journalctl -u vmtoolsd -n 50

# Réinstaller
apt remove --purge open-vm-tools
apt update && apt install open-vm-tools
systemctl enable --now vmtoolsd
systemctl enable --now vgauth
```

### Terraform continue de timeout
1. Vérifier que le service est actif : `systemctl status <service>`
2. Redémarrer la VM pour charger les drivers
3. Attendre 30 secondes après le démarrage
4. Relancer `terraform plan`

## 6. Fichiers concernés

```
terraform/cloudinit/
├── vendor-config-proxmox.yaml  # Auto-install QEMU Guest Agent
├── vendor-config-vmware.yaml   # Auto-install VMware Tools
└── user-config.yaml            # Configuration commune (users, SSH, etc.)

ansible/playbooks/
├── install-qemu-agent.yml      # Playbook QEMU Guest Agent
├── install-vmware-tools.yml    # Playbook VMware Tools
└── orchestrate.yml             # Orchestrateur avec tags
```

## 7. Résumé des commandes

| Action | Commande |
|--------|----------|
| Installer QEMU Agent | `./scripts/deploy-ansible.sh --tags qemu-agent` |
| Installer VMware Tools | `./scripts/deploy-ansible.sh --tags vmware-tools` |
| Installer les deux | `./scripts/deploy-ansible.sh --tags agent` |
| Installer sur une VM | `./scripts/deploy-ansible.sh --tags agent --limit vm-name` |
| Mode dry-run | `./scripts/deploy-ansible.sh --tags agent --check` |
