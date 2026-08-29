#!/usr/bin/env bash
# Copy samples into working locations and prepare directories.
# Does NOT download anything from the internet.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

# Expand vendored bootstrap_init role if missing
if [[ ! -f kickstart-generator/roles/bootstrap_init/tasks/main.yml ]]; then
  if [[ -f vendor/bootstrap_init_role.tar.gz.b64 ]]; then
    echo "    extracting bootstrap_init role from vendor archive"
    mkdir -p kickstart-generator
    base64 -d vendor/bootstrap_init_role.tar.gz.b64 | tar xzf - -C kickstart-generator
  fi
fi

echo "==> rhis-satellite-kickstart setup"
echo "    REPO_ROOT=${REPO_ROOT}"

if [[ ! -f environment.conf ]]; then
  if [[ -f config/environment.conf.sample ]]; then
    sed "s|^REPO_ROOT=.*|REPO_ROOT=\"${REPO_ROOT}\"|" config/environment.conf.sample > environment.conf
    echo "    created environment.conf (edit DOMAIN and paths)"
  else
    echo "ERROR: config/environment.conf.sample missing" >&2
    exit 1
  fi
else
  echo "    environment.conf already exists — leaving unchanged"
fi

# shellcheck disable=SC1091
source environment.conf

mkdir -p "${VAULT_DIR}"
chmod 700 "${VAULT_DIR}"

if [[ ! -f "${VAULT_FILE}" ]]; then
  cp config/rhis_builder_vault.yml.sample "${VAULT_FILE}"
  chmod 600 "${VAULT_FILE}"
  echo "    created ${VAULT_FILE} (mode 600) — replace CHANGEME values, then encrypt"
else
  echo "    vault already present at ${VAULT_FILE}"
fi

mkdir -p kickstart-generator/group_vars/provisioner
if [[ ! -f kickstart-generator/group_vars/provisioner/satellite_init_vars.yml ]]; then
  cp config/satellite_init_vars.yml.sample \
     kickstart-generator/group_vars/provisioner/satellite_init_vars.yml
  echo "    created kickstart-generator/group_vars/provisioner/satellite_init_vars.yml"
fi

DOMAIN_SAFE="${DOMAIN:-CHANGEME.example.com}"
BASEVARS_NAME="${DOMAIN_SAFE}_inventory_basevars.yml"
if [[ ! -f "inventory-generator/${BASEVARS_NAME}" ]]; then
  mkdir -p inventory-generator
  if [[ -f config/inventory_basevars.yml.sample ]]; then
    cp config/inventory_basevars.yml.sample "inventory-generator/${BASEVARS_NAME}"
    echo "    created inventory-generator/${BASEVARS_NAME}"
  fi
fi

if [[ -f kickstart-generator/requirements.yml ]]; then
  echo
  echo "    Install Ansible collections (once, while online if needed):"
  echo "      ansible-galaxy collection install -r kickstart-generator/requirements.yml"
fi

cat << NEXT

==> Next steps
  1. Edit environment.conf
  2. Edit inventory-generator/${BASEVARS_NAME} (optional inventory phase)
  3. Edit kickstart-generator/group_vars/provisioner/satellite_init_vars.yml
  4. Run:  scripts/generate-passwords.sh   then fill vault
  5. ansible-vault encrypt ${VAULT_FILE}
  6. Optional: scripts/generate-inventory.sh
  7. Mount OEMDRV (or use --iso) and run: scripts/generate-kickstart.sh
NEXT
