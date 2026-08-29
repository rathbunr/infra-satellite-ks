# OpenSCAP SSG Datastreams Omitted

The following files were intentionally omitted from this vendored copy
to keep the repository size manageable (~67 MiB total):

- ssg-rhel7-ds.xml
- ssg-rhel8-ds.xml
- ssg-rhel9-ds.xml

These are only needed when configuring OpenSCAP compliance policies
in Satellite — NOT for OEMDRV kickstart generation.

If you need them, download from the upstream repository:
  https://github.com/parmstro/rhis-builder-inventory

Or install the scap-security-guide package:
  dnf install scap-security-guide
  ls /usr/share/xml/scap/ssg/content/
