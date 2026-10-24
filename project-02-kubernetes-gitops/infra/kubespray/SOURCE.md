# Vendored Kubespray source

This directory is copied from `/home/ubuntu/kubespray` at revision
`212ac5eeed8c10715faabc9ebbed4e16c727888e` from
`https://github.com/Rattanchhan/kubespray.git`.

The Kubespray implementation is kept unchanged. Project-specific topology and
settings live only under `inventory/project02/`. To refresh the vendor tree,
copy a reviewed local checkout again, exclude its `.git` directory, restore
`inventory/project02/`, and update this revision record plus
`../versions.yml` in the same change.
