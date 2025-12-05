#!/bin/bash
# Ansible Aliases - Commandes les plus utilisées

# bash
alias ll='ls -laFh'


# Playbook
alias ap='ansible-playbook'
alias apc='ansible-playbook --check'
alias apd='ansible-playbook --diff'
alias apcd='ansible-playbook --check --diff'
alias apv='ansible-playbook -vvv'
alias apt='ansible-playbook --syntax-check'

# Ansible commandes de base
alias a='ansible'
alias aa='ansible all'
alias aping='ansible all -m ping'
alias ainv='ansible-inventory'
alias ainvl='ansible-inventory --list'
alias ainvg='ansible-inventory --graph'

# Vault
alias av='ansible-vault'
alias ave='ansible-vault edit'
alias avc='ansible-vault create'
alias avd='ansible-vault decrypt'
alias avenc='ansible-vault encrypt'
alias avv='ansible-vault view'

# Galaxy
alias ag='ansible-galaxy'
alias agi='ansible-galaxy install'
alias agii='ansible-galaxy install -r requirements.yml'
alias agl='ansible-galaxy list'

# Config et doc
alias acfg='ansible-config'
alias adoc='ansible-doc'
alias adocl='ansible-doc -l'

# Playbook avec tags
alias apt-tag='ansible-playbook --list-tags'
alias apt-task='ansible-playbook --list-tasks'
alias apt-host='ansible-playbook --list-hosts'

# Logs et debug
alias apvv='ansible-playbook -vv'
alias apvvv='ansible-playbook -vvv'
alias apvvvv='ansible-playbook -vvvv'

# Utilitaires
alias ap-dry='ansible-playbook --check --diff'
alias ap-limit='ansible-playbook --limit'
alias ap-tags='ansible-playbook --tags'
alias ap-skip='ansible-playbook --skip-tags'

# OpenTofu / Terraform
alias tf='tofu'
alias tfi='tofu init'
alias tfp='tofu plan'
alias tfa='tofu apply'
alias tfd='tofu destroy'
alias tfv='tofu validate'
alias tff='tofu fmt'
alias tfs='tofu show'
alias tfo='tofu output'
alias tfr='tofu refresh'
alias tfw='tofu workspace'
alias tfwl='tofu workspace list'
alias tfws='tofu workspace select'

# Configuration et orchestration
alias csv2yaml='python3 /root/config/csv-to-config.py'
alias generate-config='python3 /root/config/csv-to-config.py'
alias orchestrate='ansible-playbook /root/ansible/playbooks/orchestrate-deployment.yml'
alias orchestrate-apply='ansible-playbook /root/ansible/playbooks/orchestrate-deployment.yml -e auto_apply=true'
alias orchestrate-fast='ansible-playbook /root/ansible/playbooks/orchestrate-deployment.yml -e auto_apply=true -e ansible_parallel=5'
alias deploy-vms='orchestrate-apply'
alias deploy-vms-fast='orchestrate-fast'

# Gestion des VMs
alias list-vms='cd /root/terraform && tofu state list | grep vms_csv'

