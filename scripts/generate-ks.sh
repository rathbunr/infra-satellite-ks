#!/usr/bin/env bash
# Convenience wrapper to generate the Satellite OEMDRV kickstart.
# Run from inside a cloned rhis-builder-bootstrap-init directory.
#
# Usage:
#   ./generate-ks.sh /path/to/secure/vault/rhis_builder_vault.yml
#
# Environment overrides (optional):
#   INVENTORY_PATH   – Ansible inventory (default: inventory)
#   LIMIT            – --limit value (default: provisioner)
#   HOSTS_VAR        – name of the host list variable (default: satellite_bootstrap_init_hosts)

set -euo pipefail

VAULT_PATH="${1:-}"
if [[ -z "${VAULT_PATH}" ]]; then
  echo "Usage: $0 /path/to/secure/vault/rhis_builder_vault.yml" >&2
  exit 1
fi

if [[ ! -f "${VAULT_PATH}" ]]; then
  echo "Vault file not found: ${VAULT_PATH}" >&2
  exit 1
fi

INVENTORY_PATH="${INVENTORY_PATH:-inventory}"
LIMIT="${LIMIT:-provisioner}"
HOSTS_VAR="${HOSTS_VAR:-satellite_bootstrap_init_hosts}"

echo "==> Generating OEMDRV kickstart"
echo "    vault     : ${VAULT_PATH}"
echo "    inventory : ${INVENTORY_PATH}"
echo "    limit     : ${LIMIT}"
echo "    hosts var : ${HOSTS_VAR}"
echo

ansible-playbook -i "${INVENTORY_PATH}" --limit "${LIMIT}" main.yml \
  -e "vault_path=${VAULT_PATH}" \
  -e "bootstrap_init_hosts={{ ${HOSTS_VAR} }}" \
  --ask-vault-pass

echo
echo "==> Done. Check bootstrap_init_oem_dir (default /mnt/OEMDRV) for ks.cfg"
echo "    or bootstrap_init_iso_dir for the generated ISO when generate_oemdrv_iso: true."
