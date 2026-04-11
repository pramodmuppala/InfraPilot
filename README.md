# Combined Tomcat Remote Deployment Package

This package combines the **base Tomcat deployment/configuration** flow and the **instance scaling** flow into one remote-execution Ansible package for your Fedora control plane.

## What this package does

- Runs from **Fedora** against **remote Ubuntu** targets over SSH
- Installs prerequisite packages on Ubuntu when requested
- Creates or reuses a shared `CATALINA_HOME`
- Creates or updates `CATALINA_BASE` instances under `/opt/tomcat`
- Generates per-instance `setenv.sh` and `server.xml`
- Starts missing Tomcat instances
- Optionally destroys extra instances when scaling down
- Runs simple HTTP health checks after deployment

## Included flows

### 1. Base install / configure
Use `playbooks/install_configure_tomcat.yml` to:
- install Java and utilities
- prepare Tomcat directories
- deploy `app1`
- generate config for `app1`
- validate XML with `xmllint`
- start Tomcat

### 2. Scale instances
Use `playbooks/scale_tomcat_instances.yml` to:
- create additional instances (`app2`, `app3`, ...)
- assign offset ports using `port_stride`
- keep existing instances untouched
- optionally destroy extra instances with `destroy_enabled=true`

## Lab mapping

- Fedora: control plane
- Ubuntu 1: tomcat-node-1
- Ubuntu 2: tomcat-node-2
- Windows: traffic generator

## Files to update first

### Inventory
Edit `inventory/lab.ini`

### Variables
Edit `group_vars/tomcat.yml`

Pay special attention to:
- `tomcat.java_packages`
- `tomcat.shared_home`
- `tomcat.archive_url`
- `tomcat.archive_version`
- `tomcat.runtime_user`
- `tomcat.health_path`

## Quick start

### Connectivity test
```bash
ansible -i inventory/lab.ini tomcat -m ping
```

### Base install on both Ubuntu nodes
```bash
ansible-playbook -i inventory/lab.ini playbooks/install_configure_tomcat.yml
```

### Scale to 2 instances on both Ubuntu nodes
```bash
ansible-playbook -i inventory/lab.ini playbooks/scale_tomcat_instances.yml -e '{"tomcat":{"instance_count":2}}'
```

### Scale down to 1 instance and remove extras
```bash
ansible-playbook -i inventory/lab.ini playbooks/scale_tomcat_instances.yml -e '{"tomcat":{"instance_count":1, "destroy_enabled":true}}'
```

## Notes

- This package is intentionally **remote-execution first**. It does **not** use `connection: local`.
- `validate_server_xml` is not split into a separate role here. XML validation is handled inline with `xmllint`.
- The scaling playbook is designed for **single-host multi-instance Tomcat** on each Ubuntu VM.
- If you want application WAR deployment next, add it as a separate role after the base instance creation flow.

## Supported Natural Language Prompts

InfraPilot currently supports clear desired-state prompts for Java/Tomcat deployment, scaling, verification, and recovery workflows.

### Recommended prompt patterns

#### Deploy
- Deploy a scalable Java app with 1 instance
- Deploy a scalable Java app with 5 instances
- Deploy a scalable Java app with 5 instances and auto-recovery
- Deploy a Java app on Tomcat with 3 instances
- Deploy a Tomcat-based Java app with 4 JVMs

#### Scale up
- Increase JVMs to 5
- Increase Tomcats to 4
- Increase Tomcat instances to 5
- Scale JVMs to 5
- Scale Tomcats to 5
- Scale instances to 4
- Set instances to 5
- Run 5 JVMs

#### Scale down
- Decrease JVMs to 2
- Reduce JVMs to 1
- Reduce Tomcats to 1
- Scale down to 1 instance
- Scale Tomcats to 1
- Set instances to 1

#### Auto-recovery
- Deploy a scalable Java app with 5 instances and auto-recovery
- Increase JVMs to 5 with auto-recovery
- Scale Tomcats to 4 with auto-recovery

### Supported synonyms

InfraPilot currently treats the following terms as equivalent for scaling requests:

- JVM / JVMs
- Tomcat / Tomcats
- instance / instances
- node / nodes

These are normalized internally to the desired Tomcat instance count.

### Best prompts for demos

- Deploy a scalable Java app with 1 instance and auto-recovery
- Deploy a scalable Java app with 5 instances and auto-recovery
- Increase JVMs to 5
- Reduce JVMs to 1
- Scale Tomcats to 4
- Scale instances to 5 with auto-recovery

### Avoid vague prompts

For the current version, avoid ambiguous phrases such as:

- Add more JVMs
- Make it bigger
- Scale up a bit
- Optimize deployment
- Make it highly available

Use explicit prompts with a numeric desired count instead.


python3 scripts/summarize_results.py experiments_output/results.csv
python3 scripts/generate_plots.py experiments_output/results.csv experiments_output/plots