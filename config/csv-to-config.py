#!/usr/bin/env python3
"""
Convertit le fichier CSV en configuration YAML pour Terraform et Ansible
Usage: python3 csv-to-config.py
"""

import csv
import yaml
import sys
from pathlib import Path

def parse_list(value):
    """Parse une chaîne séparée par des virgules en liste"""
    if not value or value.strip() == "":
        return []
    return [item.strip() for item in value.split(',')]

def parse_playbooks(playbooks_str, vars_str, db_backup_file='', documents_backup_file='', dolibarr_domain='', git_repo_url='', git_branch=''):
    """Parse les playbooks et leurs variables, en ajoutant automatiquement les fichiers de backup, config Dolibarr, URL Git et branche"""
    if not playbooks_str or playbooks_str.strip() == "":
        return []
    
    playbooks = parse_list(playbooks_str)
    result = []
    
    # Parse les variables si elles existent
    vars_by_playbook = []
    if vars_str and vars_str.strip():
        # Les playbooks sont séparés par ; et les vars par |
        vars_by_playbook = vars_str.split(';')
    
    for idx, playbook in enumerate(playbooks):
        playbook_config = {'name': playbook}
        vars_dict = {}
        
        # Ajouter les variables si elles existent pour ce playbook
        if idx < len(vars_by_playbook) and vars_by_playbook[idx].strip():
            for var_pair in vars_by_playbook[idx].split('|'):
                if '=' in var_pair:
                    key, value = var_pair.split('=', 1)
                    vars_dict[key.strip()] = value.strip()
        
        # Injecter automatiquement les variables Dolibarr pour deploy-dolibarr.yml uniquement
        if 'deploy-dolibarr' in playbook.lower():
            if git_branch and git_branch.strip():
                # On passe uniquement git_branch, le rôle Dolibarr l'utilisera avec un fallback sur dolibarr_version
                vars_dict['git_branch'] = git_branch.strip()
            if dolibarr_domain and dolibarr_domain.strip():
                vars_dict['dolibarr_domain'] = dolibarr_domain.strip()
            if git_repo_url and git_repo_url.strip():
                vars_dict['git_repo_url'] = git_repo_url.strip()
        
        # Injecter automatiquement les fichiers de backup pour restore-dolibarr-db.yml
        if 'restore-dolibarr-db' in playbook.lower():
            if db_backup_file and db_backup_file.strip():
                vars_dict['backup_file'] = db_backup_file.strip()
            if documents_backup_file and documents_backup_file.strip():
                vars_dict['documents_backup_file'] = documents_backup_file.strip()
        
        if vars_dict:
            playbook_config['vars'] = vars_dict
        
        result.append(playbook_config)
    
    return result

def validate_duplicates(vms):
    """Vérifie les doublons d'IP, d'adresses MAC, de noms et de VMID"""
    errors = []
    warnings = []
    
    # Vérifier les doublons d'IP
    ip_map = {}
    for vm in vms:
        ip = vm['ip']
        if ip in ip_map:
            errors.append(f"❌ Doublon IP: {ip} utilisée par '{vm['name']}' et '{ip_map[ip]}'")
        else:
            ip_map[ip] = vm['name']
    
    # Vérifier les doublons d'adresses MAC
    mac_map = {}
    for vm in vms:
        mac = vm['mac'].upper()  # Normaliser en majuscules
        if mac in mac_map:
            errors.append(f"❌ Doublon MAC: {mac} utilisée par '{vm['name']}' et '{mac_map[mac]}'")
        else:
            mac_map[mac] = vm['name']
    
    # Vérifier les doublons de noms
    name_map = {}
    for vm in vms:
        name = vm['name']
        if name in name_map:
            errors.append(f"❌ Doublon Nom: '{name}' défini plusieurs fois")
        else:
            name_map[name] = True
    
    # Vérifier les doublons de VMID
    vmid_map = {}
    for vm in vms:
        vmid = vm['vmid']
        if vmid in vmid_map:
            errors.append(f"❌ Doublon VMID: {vmid} utilisé par '{vm['name']}' et '{vmid_map[vmid]}'")
        else:
            vmid_map[vmid] = vm['name']
    
    # Vérifier les plages IP conseillées par environnement
    for vm in vms:
        env = vm['environment']
        ip = vm['ip']
        ip_parts = ip.split('.')
        if len(ip_parts) == 4:
            last_octet = int(ip_parts[3])
            
            # Conventions recommandées
            if env == 'prod' and not (100 <= last_octet <= 109):
                warnings.append(f"⚠️  '{vm['name']}' (prod): IP {ip} hors plage recommandée .100-.109")
            elif env == 'preprod' and not (110 <= last_octet <= 119):
                warnings.append(f"⚠️  '{vm['name']}' (preprod): IP {ip} hors plage recommandée .110-.119")
            elif env == 'dev' and not (120 <= last_octet <= 129):
                warnings.append(f"⚠️  '{vm['name']}' (dev): IP {ip} hors plage recommandée .120-.129")
    
    return errors, warnings

def csv_to_yaml(csv_file, yaml_file):
    """Convertit le CSV en YAML"""
    vms = []
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            vm = {
                'name': row['name'],
                'vmid': int(row['vmid']),
                'environment': row['environment'],
                'provider': row.get('provider', 'proxmox'),  # Par défaut: proxmox
                'node': row['node'],
                'description': row['description'],
                'cores': int(row['cores']),
                'memory': int(row['memory']),
                'disk_size': int(row['disk_size']),
                'ip': row['ip'],
                'gateway': row['gateway'],
                'mac': row['mac'],
                'tags': parse_list(row['tags']),
                'ansible_groups': parse_list(row['ansible_groups']),
            }
            
            # Ajouter les playbooks s'ils existent
            playbooks = parse_playbooks(
                row.get('playbooks', ''), 
                row.get('playbook_vars', ''),
                row.get('db_backup_file', ''),
                row.get('documents_backup_file', ''),
                row.get('dolibarr_domain', ''),
                row.get('git_repo_url', ''),
                row.get('git_branch', '')
            )
            if playbooks:
                vm['playbooks'] = playbooks
            
            vms.append(vm)
    
    # Validation des doublons
    errors, warnings = validate_duplicates(vms)
    
    # Afficher les erreurs
    if errors:
        print("\n🚨 ERREURS DÉTECTÉES:")
        for error in errors:
            print(f"  {error}")
        print("\n❌ Conversion annulée à cause des erreurs ci-dessus")
        sys.exit(1)
    
    # Afficher les avertissements
    if warnings:
        print("\n⚠️  AVERTISSEMENTS:")
        for warning in warnings:
            print(f"  {warning}")
        print()
    
    # Configuration globale
    config = {
        'vms': vms,
        'global': {
            'proxmox_node': 'pve01',
            'proxmox_datastore': 'local-lvm',
            'network_bridge': 'vmbr0',
            'network_model': 'virtio',
            'dns_servers': ['192.168.1.1', '8.8.8.8'],
            'default_user': 'ansible',
            'ansible_user': 'ansible',
            'ansible_python_interpreter': '/usr/bin/python3'
        }
    }
    
    # Écrire le YAML
    with open(yaml_file, 'w', encoding='utf-8') as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    
    print(f"✅ Configuration convertie: {csv_file} → {yaml_file}")
    print(f"📊 {len(vms)} VM(s) chargée(s)")
    for vm in vms:
        playbook_count = len(vm.get('playbooks', []))
        print(f"   - {vm['name']}: {playbook_count} playbook(s)")

if __name__ == '__main__':
    script_dir = Path(__file__).parent
    csv_file = script_dir / 'vms.csv'
    yaml_file = script_dir / 'vms-config.yml'
    
    if not csv_file.exists():
        print(f"❌ Erreur: {csv_file} n'existe pas", file=sys.stderr)
        sys.exit(1)
    
    try:
        csv_to_yaml(csv_file, yaml_file)
    except Exception as e:
        print(f"❌ Erreur: {e}", file=sys.stderr)
        sys.exit(1)
