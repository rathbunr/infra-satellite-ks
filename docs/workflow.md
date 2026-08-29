# Phase-by-phase workflow

## Prerequisites
- RHEL 9, ansible-core ≥ 2.14
- Collections: `ansible-galaxy collection install -r kickstart-generator/requirements.yml`
- Root/sudo for OEMDRV; CDN org + activation key for connected installs

## Setup
```bash
./scripts/setup.sh
# edit environment.conf, basevars, satellite_init_vars.yml
./scripts/generate-passwords.sh
ansible-vault encrypt "$VAULT_FILE"
```

## Inventory (optional)
```bash
./scripts/generate-inventory.sh
```

## Kickstart
```bash
./scripts/generate-kickstart.sh
# or
./scripts/generate-kickstart.sh --iso
```

See kickstart-delivery.md for USB / ISO / disconnected methods.
