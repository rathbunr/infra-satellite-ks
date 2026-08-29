# Vendored upstream sources

| Upstream | Commit SHA | Path |
|----------|------------|------|
| parmstro/rhis-builder-inventory | `69245a9bdfb6f79346761e44329d47df1a72795f` | `inventory-generator/` |
| parmstro/rhis-builder-bootstrap-init | `3ded8886f2012f83279129fe6b5237864bf654ad` | `kickstart-generator/` |

## Omissions

OpenSCAP SSG XML datastreams (~67 MiB) were omitted from `inventory-generator/inventory_template/files/`.
They are not required for OEMDRV kickstart generation. See `inventory-generator/inventory_template/files/SSG_XML_OMITTED.md`.

## Updating from upstream

```bash
# Check what's changed since the vendored commit
git clone --bare https://github.com/parmstro/rhis-builder-inventory.git /tmp/rbi
git -C /tmp/rbi log --oneline 69245a9b..HEAD

git clone --bare https://github.com/parmstro/rhis-builder-bootstrap-init.git /tmp/rbbi
git -C /tmp/rbbi log --oneline 3ded8886..HEAD
```
