#!/usr/bin/env bash
export ANSIBLE_STDOUT_CALLBACK=default
set -euo pipefail
cd "$(dirname "$0")/.."
ansible-playbook -i inventory/lab.ini playbooks/install_configure_tomcat.yml -e @group_vars/tomcat.yml