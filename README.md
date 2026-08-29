# rhis-satellite-kickstart

Self-contained repository that generates an **OEMDRV kickstart** for a Red Hat Satellite server on RHEL 9.

Upstream components are **vendored** (no runtime clone of GitHub):

- [rhis-builder-inventory](https://github.com/parmstro/rhis-builder-inventory) → `inventory-generator/`
- [rhis-builder-bootstrap-init](https://github.com/parmstro/rhis-builder-bootstrap-init) → `kickstart-generator/`

See [VENDORED.md](VENDORED.md) for commit SHAs. After the initial clone this tree is intended to work **offline** on a RHEL 9 provisioner (pre-install Ansible collections while you still have network if needed).

## Prerequisites

- RHEL 9 with `ansible-core` ≥ 2.14, `git`
- Root or sudo (OEMDRV mount)
- Active Red Hat subscription, CDN org ID, activation key (connected installs)
- SSH key pair for automation user (`ansiblerunner`)
- Collections:

```bash
ansible-galaxy collection install -r kickstart-generator/requirements.yml
```

## Quick start

```bash
git clone https://github.com/rathbunr/infra-satellite-ks.git
cd infra-satellite-ks

./scripts/setup.sh
# 1) edit environment.conf
# 2) edit inventory-generator/<domain>_inventory_basevars.yml
# 3) edit kickstart-generator/group_vars/provisioner/satellite_init_vars.yml

./scripts/generate-passwords.sh    # paste into vault file
ansible-vault encrypt "${VAULT_FILE:-$HOME/.rhis-vault/rhis_builder_vault.yml}"

./scripts/generate-inventory.sh    # optional — full RHIS deployment tree
./scripts/generate-kickstart.sh    # or --iso for virtual media
```

## Kickstart delivery

| Method | How |
|--------|-----|
| USB OEMDRV | Mount labeled `OEMDRV`, run `generate-kickstart.sh`, boot RHEL 9 DVD + OEMDRV |
| ISO virtual media | `generate_oemdrv_iso: true`, run with `--iso`, attach both ISOs via BMC |
| Disconnected | `disconnected: true` on host entry |

Details: [docs/kickstart-delivery.md](docs/kickstart-delivery.md).

## After install

When Satellite is reachable over SSH, continue with the **rhis-provisioner** container using launch scripts produced under `inventory-generator/deployments/<domain>/` (or your wider RHIS process).

## Updating from upstream

Compare SHAs in [VENDORED.md](VENDORED.md) to current upstream `main`, then refresh the vendored trees and re-test.

## Layout

```
config/                 # samples (CHANGEME placeholders)
inventory-generator/    # vendored inventory engine
kickstart-generator/    # vendored bootstrap_init role + playbooks
scripts/                # setup, inventory, kickstart, passwords
docs/                   # workflow, delivery, variables
```

## License

GPL-3.0 (aligned with upstream rhis-builder projects).
