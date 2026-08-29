# rhis-satellite-kickstart (infra-satellite-ks)

Self-contained OEMDRV kickstart generator for a Red Hat Satellite server on RHEL 9.

Upstream components are vendored so the tree works **offline after clone** (install Ansible collections while you still have network):

- `kickstart-generator/` — from [rhis-builder-bootstrap-init](https://github.com/parmstro/rhis-builder-bootstrap-init) (`3ded8886`)
- `inventory-generator/` — from [rhis-builder-inventory](https://github.com/parmstro/rhis-builder-inventory) (`69245a9b`) — expand from `vendor/` if not already present

See [VENDORED.md](VENDORED.md).

## Quick start

```bash
git clone https://github.com/rathbunr/infra-satellite-ks.git
cd infra-satellite-ks
./scripts/setup.sh
# edit environment.conf, satellite_init_vars.yml, vault
ansible-galaxy collection install -r kickstart-generator/requirements.yml
./scripts/generate-passwords.sh
ansible-vault encrypt "$HOME/.rhis-vault/rhis_builder_vault.yml"
./scripts/generate-kickstart.sh          # or --iso
```

CLI and AAP 2.7 both run the same `kickstart-generator/main.yml` playbook with `vault_path` and a provisioner inventory.

## License

GPL-3.0
