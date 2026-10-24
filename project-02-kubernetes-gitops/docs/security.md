# Security model

- SSH is restricted to the controller CIDR and uses public-key authentication.
- Kubernetes API access must be restricted by firewall or VPN.
- `master01` remains tainted; `master02` is the only schedulable control plane.
- CI can publish images and propose Git changes but receives no kubeconfig.
- Argo CD repository credentials are read-only and stored in an encrypted
  Ansible Vault file before being placed in a Kubernetes Secret.
- Application containers run non-root, drop all capabilities, disable service
  account token mounting, use resource limits and a read-only root filesystem.
- NetworkPolicy defaults to deny and permits only Traefik ingress and DNS.
- Headlamp receives no cluster-admin binding; the supplied viewer identity is
  read-only and namespace-scoped. Headlamp login tokens are short-lived and
  generated on demand, so they are deliberately not persisted in Vault.
- Secrets, kubeconfigs, keys, generated inventories and private evidence are
  ignored by Git. Run secret scanning in the hosting platform before merging.

