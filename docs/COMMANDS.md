# Commands

## Ping targets
```bash
ansible -i inventory/lab.ini tomcat -m ping
```

## Base install and configure
```bash
./scripts/run_base_install.sh
```

## Scale to 2 instances
```bash
./scripts/run_scale.sh -e '{"tomcat":{"instance_count":2}}'
```

## Scale down to 1 and destroy extras
```bash
./scripts/run_scale.sh -e '{"tomcat":{"instance_count":1,"destroy_enabled":true}}'
```
