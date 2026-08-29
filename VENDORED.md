# Vendored upstream sources

| Upstream | Commit SHA | Path |
|----------|------------|------|
| parmstro/rhis-builder-inventory | `69245a9bdfb6f79346761e44329d47df1a72795f` | `inventory-generator/` (+ `vendor/vendor-inventory-generator.tar.gz`) |
| parmstro/rhis-builder-bootstrap-init | `3ded8886f2012f83279129fe6b5237864bf654ad` | `kickstart-generator/` |

OpenSCAP SSG XML datastreams (~67MiB) were omitted from the inventory vendor copy; they are not required for OEMDRV kickstart generation.

`scripts/setup.sh` extracts `vendor/*.tar.gz` into place if the trees are not already expanded.
