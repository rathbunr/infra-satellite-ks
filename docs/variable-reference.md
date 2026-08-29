# Variable reference

## Inventory basevars (key)
- basevars_global_domain_name
- default_network / _prefix / _mask
- rhis_timezone, rhis_system_count

## bootstrap_init host keys
Match upstream bootstrap_init_vars.SAMPLE.yml: rhis_role, hostname, domain, mac, ipv4_*, name_server*, root_enc_pass, grub_enc_pass, boot_disk, root_disk, lv_*, username, user_enc_pass, user_sudoer_policy, ssh_pub_key, org, activation_key, generate_oemdrv_iso, optional disconnected.

## Vault (7)
encrypted_root_pass_vault, encrypted_grub_pass_vault, encrypted_user_pass_vault, user_sudoer_policy_vault, ssh_pub_key_vault, cdn_organization_vault, cdn_activation_key_vault.
