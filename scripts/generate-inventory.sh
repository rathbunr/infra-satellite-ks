#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"
if [[ ! -f environment.conf ]]; then echo "ERROR: run setup.sh first" >&2; exit 1; fi
# shellcheck disable=SC1091
source environment.conf
DOMAIN="${DOMAIN:?DOMAIN must be set}"
BASEVARS_NAME="${DOMAIN}_inventory_basevars.yml"
BASEVARS_PATH="${REPO_ROOT}/inventory-generator/${BASEVARS_NAME}"
if [[ ! -f "${BASEVARS_PATH}" ]]; then echo "ERROR: ${BASEVARS_PATH} not found" >&2; exit 1; fi
if [[ ! -f inventory-generator/inventory_update.yml ]]; then
  echo "ERROR: inventory engine not vendored yet. Expand vendor/vendor-inventory-generator.tar.gz into inventory-generator/" >&2
  exit 1
fi
cd "${REPO_ROOT}/inventory-generator"
echo "==> Generating deployment inventory for ${DOMAIN}"
if command -v ansible-playbook >/dev/null 2>&1; then
  ansible-playbook -e "basevars_file=${BASEVARS_NAME}" inventory_update.yml
else
  ./inventory_update.sh -b "${BASEVARS_NAME}"
fi
ls -la deployments/ 2>/dev/null || true
