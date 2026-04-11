#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ansible-playbook -i inventory/lab.ini playbooks/scale_tomcat_instances.yml -e @group_vars/tomcat.yml
