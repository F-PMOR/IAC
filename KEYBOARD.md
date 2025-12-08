# Configuration du Clavier (AZERTY) pour Console Proxmox et VMware

## 🎯 Problème

Par défaut, les consoles Proxmox et VMware utilisent un clavier QWERTY, ce qui pose problème pour saisir des caractères français (a/q, z/w, m/;, etc.).

## ✅ Solutions

### 1️⃣ Nouvelles VMs (automatique via cloud-init)

Les nouvelles VMs créées par Terraform auront automatiquement le clavier français configuré grâce à `user-config.yaml`.

**Aucune action nécessaire** - c'est automatique au premier boot !

### 2️⃣ VMs existantes (via Ansible)

Pour configurer le clavier sur des VMs déjà créées :

```bash
# Dans le container IAC-TFA
cd /root/ansible

# Configurer le clavier sur toutes les VMs
ansible-playbook -i inventory/proxmox/inventory.ini \
  playbooks/configure-keyboard.yml

# Configurer le clavier sur une VM spécifique
ansible-playbook -i inventory/proxmox/inventory.ini \
  playbooks/configure-keyboard.yml \
  --limit dolibarr-prod01
```

### 3️⃣ Configuration manuelle (dans la console)

Si vous êtes déjà connecté en console (Proxmox/VMware) :

```bash
# Appliquer immédiatement (session actuelle)
sudo loadkeys fr

# Configuration permanente
sudo dpkg-reconfigure keyboard-configuration
# Sélectionnez:
# - Generic 105-key PC
# - French
# - Default
# - No compose key

# Appliquer la configuration
sudo setupcon -k --force

# Vérifier
localectl status
```

## 🔧 Configuration appliquée

Le clavier sera configuré avec les paramètres suivants :

- **Layout**: `fr` (Français)
- **Model**: `pc105` (PC 105 touches)
- **Variant**: Standard AZERTY
- **Locale**: `fr_FR.UTF-8`

## 📝 Fichiers modifiés

- `/etc/default/keyboard` - Configuration du clavier
- `/etc/vconsole.conf` - Configuration de la console virtuelle
- Cloud-init: Applique automatiquement `loadkeys fr` au boot

## 🚀 Vérification

Pour vérifier que le clavier est bien configuré :

```bash
# Voir la configuration actuelle
localectl status

# Tester en tapant des caractères français
# a/q, z/w, m/;, etc.
```

## ⚠️ Note pour Proxmox/VMware

**Proxmox** : Le clavier de la console web est géré par le navigateur. Si vous avez toujours un QWERTY dans la console web, c'est normal - le clavier AZERTY fonctionne dans la VM elle-même.

**VMware** : Même comportement - la console web peut avoir un mapping différent, mais le clavier dans la VM est bien configuré.

## 💡 Astuce

Si vous devez taper temporairement en QWERTY dans une console mal configurée, voici les correspondances principales :

| AZERTY | Position QWERTY |
|--------|-----------------|
| a      | q               |
| z      | w               |
| q      | a               |
| w      | z               |
| m      | ;               |
| .      | shift + ;       |

