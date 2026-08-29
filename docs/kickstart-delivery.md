# Kickstart delivery methods

## USB OEMDRV
1. Format USB xfs/ext4, label OEMDRV, mount at OEMDRV_DIR
2. Run generate-kickstart.sh
3. Boot RHEL 9 DVD + OEMDRV; remove both before second boot

## ISO virtual media
1. generate_oemdrv_iso: true
2. generate-kickstart.sh --iso
3. Attach RHEL 9 DVD ISO + OEMDRV ISO via BMC

## Disconnected
Set disconnected: true on the host entry; CDN registration is skipped.
