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

def parse_playbooks(playbooks_str, vars_str):
    """Parse les playbooks et leurs variables"""
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
        
        # Ajouter les variables si elles existent pour ce playbook
        if idx < len(vars_by_playbook) and vars_by_playbook[idx].strip():
            vars_dict = {}
            for var_pair in vars_by_playbook[idx].split('|'):
                if '=' in var_pair:
                    key, value = var_pair.split('=', 1)
                    vars_dict[key.strip()] = value.strip()
            if vars_dict:
                playbook_config['vars'] = vars_dict
        
        result.append(playbook_config)
    
    return result

def csv_to_yaml(csv_file, yaml_file):
    """Convertit le CSV en YAML"""
    vms = []
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            vm = {
                'name': row['name'],
                'environment': row['environment'],
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
            playbooks = parse_playbooks(row.get('playbooks', ''), row.get('playbook_vars', ''))
            if playbooks:
                vm['playbooks'] = playbooks
            
            vms.append(vm)
    
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
