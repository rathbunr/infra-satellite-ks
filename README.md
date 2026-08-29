# infra-satellite-ks

Generate an OEMDRV kickstart (`ks.cfg`) for a **single Red Hat Satellite server** using the RHIS builder toolchain.

This repository packages the verified, improved workflow from:

- [rhis-builder-inventory](https://github.com/parmstro/rhis-builder-inventory)
- [rhis-builder-bootstrap-init](https://github.com/parmstro/rhis-builder-bootstrap-init)

It is intentionally thin: it holds the documentation, sample variables, and helper commands so you can produce a production-ready Satellite kickstart without forking the upstream template repos incorrectly.

**Verified against**: rhis-builder-inventory + rhis-builder-bootstrap-init (August 2026).

---

## Prerequisites

- RHEL 9 provisioner node with `ansible-core` ≥ 2.14, `git`, and `podman`
- Root or sudo access (to mount the OEMDRV volume)
- Active Red Hat subscription with a CDN organization ID and an activation key for a RHEL 9 minimal install (not required for disconnected hosts)
- SSH key pair for the automation user (convention: `ansiblerunner`)
- Internet connectivity (unless using the disconnected workflow)

---

## Phase 1 — Generate the Deployment Inventory

**Do not clone** `rhis-builder-inventory` directly. Cloning leaves the upstream remote in place and risks pushing environment-specific configuration back to the template repository. Download the archive and initialise a fresh repository pointed at your own remote:

```bash
wget https://github.com/parmstro/rhis-builder-inventory/archive/refs/heads/main.zip
unzip main.zip
mv rhis-builder-inventory-main rhis-builder-inventory
cd rhis-builder-inventory

git init -b main
git add --all
git commit -m "Initial commit"

# Point origin at your own repository — not the upstream template
git remote add origin https://github.com/<your_org_or_login>/rhis-builder-inventory.git
git remote -v
git push -u origin main
```

Copy the base variables template (prefer a hyphenated filename for filesystem safety):

```bash
cp inventory_basevars.yml your-domain_inventory_basevars.yml
```

Edit `your-domain_inventory_basevars.yml`. For a single Satellite server use the minimal set below (adjust network, timezone, and location):

```yaml
global_domain_name: "your.domain"

default_network: "192.168.0.0"
default_network_prefix: "22"
default_network_mask: "255.255.252.0"

rhis_primary_city: "YourCity"
rhis_primary_state: "YourState"
rhis_timezone: "America/New_York"
rhis_locale: "en"

rhis_aap_release_version: "2.6"

rhis_system_count:
  satellite: 1
  discosatellite: 0
  capsule: 0
  idm: 0
  aapcontroller: 0
  aaphub: 0
  quadlet: 0
```

> **Note:** Set every role you are not deploying to `0`. `rhis_system_count` only controls how many host directories and inventory entries are generated — it does not configure the hosts themselves.
>
> Networks, datastores, and other underlying infrastructure referenced in your configurations must already exist before running the RHIS provisioner.

Generate the deployment:

```bash
./inventory_update.sh -b your-domain_inventory_basevars.yml
```

Verify the output directory:

```
deployments/your.domain/
├── group_vars/
├── host_vars/
├── inventory/
├── templates/
├── vault_SAMPLES/
└── vars/
```

---

## Phase 2 — Prepare the Vault File

Copy the vault sample. Keep vault files **outside** your project directory and ensure `.gitignore` excludes any vault or credential files before committing:

```bash
cp deployments/your.domain/vault_SAMPLES/rhis_builder_vault_SAMPLE.yml.j2 \
   /path/to/secure/vault/rhis_builder_vault.yml
```

Populate the seven variables required for a **connected** Satellite kickstart:

```yaml
encrypted_root_pass_vault:      "$6$rounds=..."           # openssl passwd -6
encrypted_grub_pass_vault:      "grub.pbkdf2.sha512...."  # grub2-mkpasswd-pbkdf2
encrypted_user_pass_vault:      "$6$rounds=..."           # openssl passwd -6
user_sudoer_policy_vault:       "ansiblerunner ALL=(ALL) NOPASSWD: ALL"
ssh_pub_key_vault:              "ssh-ed25519 AAAA... ansiblerunner@provisioner"
cdn_organization_vault:         "12345678"                # Red Hat CDN org ID
cdn_activation_key_vault:       "rhis-bootstrap"          # Activation key name
```

**Generating the encrypted passwords**

- Root and user passwords: `openssl passwd -6` (no arguments — enter the password at the prompt so it never appears in shell history). Produces a SHA-512 hash (`$6$...`).
- GRUB2 bootloader password: `grub2-mkpasswd-pbkdf2` and copy the full `grub.pbkdf2.sha512.…` string.

Encrypt the vault:

```bash
ansible-vault encrypt /path/to/secure/vault/rhis_builder_vault.yml
```

> The variables above cover kickstart generation only. The full RHIS deployment (IdM, Satellite, AAP) requires many additional vault variables — see `vault_SAMPLES/` in your generated deployment.

For hosts with `disconnected: true`, the two CDN variables are not referenced and may be omitted.

---

## Phase 3 — Configure Host Variables

Clone the bootstrap-init repository (this is the **canonical** home of the role; do not use the deprecated `rhis-builder-baremetal-init` for new work):

```bash
git clone https://github.com/parmstro/rhis-builder-bootstrap-init.git
cd rhis-builder-bootstrap-init
ansible-galaxy collection install -r requirements.yml

mkdir -p group_vars/provisioner
cp bootstrap_init_vars.SAMPLE.yml group_vars/provisioner/satellite_init_vars.yml
```

A ready-to-edit sample that matches the recommended named-list pattern is also provided in this repository:

```bash
# From this repo (infra-satellite-ks)
cp samples/group_vars/provisioner/satellite_init_vars.yml \
   /path/to/rhis-builder-bootstrap-init/group_vars/provisioner/
```

Edit the file. Key values to customize: `hostname`, `domain`, `mac`, all `ipv4_*` fields, `name_server1/2`, `boot_disk`, and `root_disk`. The `{{ vault_variable }}` references resolve at runtime from the encrypted vault.

**Storage note:** Satellite requires a large `/var` — downloading all standard RHEL repositories needs approximately 900 GiB. Use a 1 TiB or larger drive. Setting `lv_var_mb: 1` tells Anaconda to grow `/var` into all remaining space.

**Partition layout:** The sizes in the sample meet CIS Level 2, DISA-STIG, and PCI-DSS partition requirements.

---

## Phase 4 — Generate the Kickstart File

### Method A: USB boot (lab method)

1. Format a USB drive with xfs or ext4, label it `OEMDRV`, and mount it:

   ```bash
   mkfs.xfs -L OEMDRV /dev/sdX1          # adjust device path
   mkdir -p /mnt/OEMDRV
   mount /dev/sdX1 /mnt/OEMDRV
   ```

2. Run the playbook (from the `rhis-builder-bootstrap-init` directory):

   ```bash
   ansible-playbook -i inventory --limit provisioner main.yml \
     -e "vault_path=/path/to/secure/vault/rhis_builder_vault.yml" \
     -e "bootstrap_init_hosts={{ satellite_bootstrap_init_hosts }}" \
     --ask-vault-pass
   ```

   > If your file defines the list as top-level `bootstrap_init_hosts:` (instead of the named `satellite_bootstrap_init_hosts`), omit the `-e "bootstrap_init_hosts=..."` argument — the role will use the default list.

3. Unmount:

   ```bash
   umount /mnt/OEMDRV
   ```

4. Insert both the OEMDRV USB and a bootable RHEL 9 DVD USB into the target system. Boot from the RHEL 9 installer — Anaconda detects the OEMDRV drive and reads `ks.cfg` automatically. Remove the USB drives before the second boot to prevent re-reading the kickstart.

### Method B: ISO via virtual media (datacenter method)

Set `generate_oemdrv_iso: true` in the host entry, then run the same playbook. The role writes `ks.cfg` and generates an ISO9660 image at:

```
/mnt/OEMDRV/ISO/satellite_satellite1.your.domain.oemdrv.iso
```

(Exact path follows `<bootstrap_init_iso_dir>/<rhis_role>_<hostname>.<domain>.oemdrv.iso`.)

Attach both the RHEL 9 DVD ISO and this OEMDRV ISO as virtual media (iDRAC, iLO, or Redfish) and boot.

### Method C: Disconnected (air-gapped) environments

Add `disconnected: true` to the host entry. This skips CDN `subscription-manager` registration and `dnf -y update` in the kickstart `%post` section. The `org` and `activation_key` fields are not required.

---

## What Happens Next

Once the Satellite node is installed and reachable over SSH, proceed to the rhis-provisioner container to configure IdM (Phase 2), Satellite (Phase 3), and AAP (Phase 4). The container launch scripts were generated during Phase 1:

```bash
cd rhis-builder-inventory
./your.domain.25.sh     # Recommended — for AAP 2.5+
```

---

## Repository Layout

```
.
├── README.md                          # This workflow
├── samples/
│   └── group_vars/provisioner/
│       └── satellite_init_vars.yml    # Ready-to-edit host definition (named list)
├── scripts/
│   └── generate-ks.sh                 # Convenience wrapper for the playbook
├── .gitignore
└── LICENSE
```

---

## Quick Reference — Password Generation

```bash
# Root / automation user (SHA-512, interactive)
openssl passwd -6

# GRUB2 bootloader password
grub2-mkpasswd-pbkdf2
```

---

## License

GPL-3.0 (consistent with the upstream RHIS builder projects).
