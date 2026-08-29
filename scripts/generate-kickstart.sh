#!/usr/bin/env bash
# Generate OEMDRV kickstart via the vendored bootstrap_init role.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

ISO_MODE=false
if [[ "${1:-}" == "--iso" ]]; then
  ISO_MODE=true
  shift
fi

if [[ ! -f environment.conf ]]; then
  echo "ERROR: environment.conf missing — run scripts/setup.sh first" >&2
  exit 1
fi
# shellcheck disable=SC1091
source environment.conf

VAULT_FILE="${VAULT_FILE:?VAULT_FILE must be set}"
OEMDRV_DIR="${OEMDRV_DIR:-/mnt/OEMDRV}"
INVENTORY_PATH="${INVENTORY_PATH:-inventory}"
LIMIT="${LIMIT:-provisioner}"
HOSTS_VAR="${HOSTS_VAR:-bootstrap_init_hosts}"

if [[ ! -f "${VAULT_FILE}" ]]; then
  echo "ERROR: vault file not found: ${VAULT_FILE}" >&2
  exit 1
fi

VARS_FILE="${REPO_ROOT}/kickstart-generator/group_vars/provisioner/satellite_init_vars.yml"
if [[ ! -f "${VARS_FILE}" ]]; then
  echo "ERROR: ${VARS_FILE} missing — run setup.sh" >&2
  exit 1
fi

if [[ "${ISO_MODE}" == "false" ]]; then
  if [[ ! -d "${OEMDRV_DIR}" ]]; then
    echo "ERROR: OEMDRV directory ${OEMDRV_DIR} does not exist." >&2
    echo "  Mount a filesystem labeled OEMDRV there, or re-run with --iso" >&2
    exit 1
  fi
  if ! mountpoint -q "${OEMDRV_DIR}" 2>/dev/null; then
    echo "WARNING: ${OEMDRV_DIR} does not appear to be a mountpoint — continuing anyway"
  fi
else
  mkdir -p "${OEMDRV_ISO_DIR:-${OEMDRV_DIR}/ISO}"
  echo "NOTE: --iso set. Ensure generate_oemdrv_iso: true in satellite_init_vars.yml"
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ERROR: ansible-playbook not found on PATH" >&2
  exit 1
fi

cd "${REPO_ROOT}/kickstart-generator"

EXTRA_HOSTS=()
if [[ "${HOSTS_VAR}" != "bootstrap_init_hosts" ]]; then
  EXTRA_HOSTS=(-e "bootstrap_init_hosts={{ ${HOSTS_VAR} }}")
fi

echo "==> Generating kickstart"
echo "    vault     : ${VAULT_FILE}"
echo "    inventory : ${INVENTORY_PATH}"
echo "    limit     : ${LIMIT}"
echo "    hosts var : ${HOSTS_VAR}"

ansible-playbook -i "${INVENTORY_PATH}" --limit "${LIMIT}" main.yml \
  -e "vault_path=${VAULT_FILE}" \
  "${EXTRA_HOSTS[@]}" \
  --ask-vault-pass

cat << POST

==> Kickstart generation finished
  USB method:
    - Confirm ks.cfg is on the OEMDRV volume (${OEMDRV_DIR})
    - umount ${OEMDRV_DIR}
    - Boot target from RHEL 9 DVD + OEMDRV USB; remove both before second boot

  ISO method (generate_oemdrv_iso: true):
    - ISO under ${OEMDRV_ISO_DIR:-${OEMDRV_DIR}/ISO}/
    - Attach RHEL 9 DVD ISO + OEMDRV ISO via virtual media and boot

  Next: when the host is up, use the rhis-provisioner container from your
  inventory-generator deployments/<domain>/ launch scripts.
POST
