# Argo CD GitOps Repository

This directory is intended to be published as the GitOps repository.

- `base/` contains shared Kubernetes resources.
- `environments/dev/` pins the development image digest and hostname.
- `environments/prod/` pins the production image digest, hostname, and replica
  count.
- `bootstrap/` contains the Argo CD AppProject and Application templates used
  by the infrastructure repository.
- `platform/` contains Helm values and platform policy manifests.

Application CI may propose changes to an environment digest, but Argo CD is
the only component that deploys those changes. Configure the webhook through
`infra/playbooks/36-gitops-bootstrap.yml`; do not commit webhook credentials to
this repository.
