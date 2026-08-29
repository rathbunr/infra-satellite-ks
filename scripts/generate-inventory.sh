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
if [[ ! -f inventory-generator/inventory_update.sh ]]; then
  echo "ERROR: inventory engine not vendored. See README for setup." >&2
  exit 1
fi
if [[ ! -d inventory-generator/inventory_template ]]; then
  echo "ERROR: inventory_template/ directory missing from inventory-generator/" >&2
  exit 1
fi
cd "${REPO_ROOT}/inventory-generator"
echo "==> Generating deployment inventory for ${DOMAIN}"
./inventory_update.sh -b "${BASEVARS_NAME}"

DEPLOY_DIR="deployments/${DOMAIN}"
if [[ -d "${DEPLOY_DIR}" ]]; then
  echo "==> Deployment generated at: inventory-generator/${DEPLOY_DIR}"
  ls -1 "${DEPLOY_DIR}/"
else
  echo "WARNING: Expected deployment directory not found at ${DEPLOY_DIR}"
  echo "Check inventory_update.sh output above for errors."
fi
