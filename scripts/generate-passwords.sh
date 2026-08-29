#!/usr/bin/env bash
set -euo pipefail
echo "==> Generate values for rhis_builder_vault.yml"
echo
if ! command -v openssl >/dev/null 2>&1; then echo "ERROR: openssl not found" >&2; exit 1; fi
echo "--- Root password (openssl passwd -6) ---"
ROOT_HASH="$(openssl passwd -6)"
echo "encrypted_root_pass_vault: \"${ROOT_HASH}\""
echo
echo "--- Automation user password (openssl passwd -6) ---"
USER_HASH="$(openssl passwd -6)"
echo "encrypted_user_pass_vault: \"${USER_HASH}\""
echo
if command -v grub2-mkpasswd-pbkdf2 >/dev/null 2>&1; then
  echo "--- GRUB password (grub2-mkpasswd-pbkdf2) ---"
  GRUB_OUT="$(grub2-mkpasswd-pbkdf2)"
  GRUB_HASH="$(echo "${GRUB_OUT}" | grep -o 'grub.pbkdf2.sha512.[^[:space:]]*' || true)"
  if [[ -n "${GRUB_HASH}" ]]; then echo "encrypted_grub_pass_vault: \"${GRUB_HASH}\""; else echo "${GRUB_OUT}"; fi
else
  echo "WARNING: grub2-mkpasswd-pbkdf2 not found"
fi
echo
echo "--- SSH public key ---"
for k in "${HOME}/.ssh/id_ed25519.pub" "${HOME}/.ssh/id_rsa.pub"; do
  if [[ -f "${k}" ]]; then echo "ssh_pub_key_vault: \"$(cat "${k}")\""; break; fi
done
echo
echo "--- CDN ---"
echo "cdn_organization_vault:  # https://access.redhat.com"
echo "cdn_activation_key_vault:  # RHEL 9 minimal activation key"
