# Project 02 — Kubernetes GitOps CI/CD

This repository is independent from Project 01. It builds a four-node
Kubespray cluster and deploys platform and application configuration through
GitOps.

## Topology

| Node | Control plane | etcd | Ordinary workloads |
| --- | --- | --- | --- |
| `master01` | yes | yes | no |
| `master02` | yes | yes | yes |
| `worker01` | no | yes | yes |
| `worker02` | no | no | yes |

The baseline uses three etcd members across `master01`, `master02`, and
`worker01`, providing an odd-member quorum. The two-control-plane API still
requires a resilient endpoint and failure testing before making a complete HA
claim.

## Repository boundaries

The working tree contains two repository-ready paths plus the infrastructure
controller:

- `ReactJS-Service-Pipeline-Deployment/`: React source, Dockerfile, and its own
  GitHub Actions workflow. Protected `dev` and `prod` branches build, push,
  pull-verify, scan, and propose the matching environment digest.
- `argocd-gitops-repository/`: desired state under `environments/dev` and
  `environments/prod`, plus platform values and Argo CD bootstrap templates.
  This path is the target of application CI promotion commits.
- `infra/`: vendored Kubespray, inventory, platform installation, Argo CD
  repository registration, and GitHub webhook creation.
- `docs/`: architecture, operations, security, and evidence.

Publish the two repository-ready directories as separate Git repositories.
Keep `infra/`, `docs/`, and the root task files in this infrastructure
repository.

Publish either directory to its dedicated repository with a configurable
branch and commit message:

```bash
just publish-react dev "Describe the React change"
just publish-gitops main "Describe the desired-state change"
```

Each task clones the target branch into a temporary directory, synchronizes
the corresponding repository-ready directory to the repository root, commits
only when content changed, and pushes the selected branch. Git credentials
must already be configured; alternatively, export `GH_TOKEN` or
`GITHUB_TOKEN` with write access to the target repository. Tokens are passed
through a temporary askpass helper and are not written into the clone URL.
Configured author identity is reused when present.
`just complete` reads `vault_github_webhook_token` from `infra/vault.yml` and
uses it only for its GitOps and React publication commands. It supports both
plaintext and Ansible-Vault-encrypted files; encrypted Vault files prompt for
their password. GitOps baseline publication preserves image names and immutable
digests previously promoted by React CI, so rerunning `just complete` without a
new React commit cannot replace a working deployment with template placeholders.
The first `publish-gitops` run normalizes the existing remote from a nested
directory to this repository-root layout; run `just gitops` immediately after
that first publication so the live Argo CD Application paths are reconciled.
`just complete` runs the full sequence in order: platform installation,
GitOps baseline publication, React `dev` publication, a wait for React CI and
its direct GitOps promotion, Argo CD bootstrap, and cluster verification. This
ensures Argo CD sees a real image digest when the Applications are created.

## React application and CI/CD

`ReactJS-Service-Pipeline-Deployment/` contains the complete storefront example, migrated to a pinned Vite
toolchain. Environment files, embedded credentials, host-level deployment
scripts, and direct-deploy workflows are intentionally excluded. The visible
release banner is populated from the immutable source revision at image build
time.

Its workflow in `ReactJS-Service-Pipeline-Deployment/.github/workflows/ci.yml`
performs for the `dev` and `prod` branches:

1. locked dependency installation, lint, unit test, production build and audit;
2. container build, SBOM/provenance generation and registry publication;
3. Trivy enforcement for high and critical image findings;
4. immutable image-digest capture;
5. a direct commit changing only `environments/<branch>/kustomization.yaml` in
   the configured GitOps target branch;
6. automatic Argo CD reconciliation.

CI never receives Kubernetes credentials. Configure `GITOPS_REPOSITORY` and,
optionally, `GITOPS_BRANCH` as repository variables. Configure `GITOPS_TOKEN`
as a narrowly scoped secret with Contents read/write access to that repository.

Kubespray is vendored from the tested local checkout at `/home/ubuntu/kubespray`.
Its exact source revision is recorded in `infra/versions.yml` and
`infra/kubespray/SOURCE.md`. The Kubespray implementation is kept intact;
Project 02 changes are confined to `infra/kubespray/inventory/project02`.

## Installation outline

1. Keep the completed Project 1 repository and its generated inventory in
   place. Project 2 reuses those four EC2 instances; it does not provision
   replacements.
2. Run `just setup`.
3. Run `just inventory`; it references Project 1 and writes the Kubespray
   inventory to
   `infra/kubespray/inventory/project02/hosts.yml`.
4. Run `just ping` and `just cluster`.

`just cluster` invokes Project 1's guarded transition playbook. It attaches a
separately owned, self-referencing Project 2 security group so only its members
can exchange Kubernetes, etcd, and overlay-network traffic. The original
Project 1 security group and its SSH/web rules remain unchanged.
5. Export the GitOps bootstrap credentials described below and run
   `just complete`. This configures the existing NLB, installs the platform,
   bootstraps Argo CD, and runs acceptance checks.

Create and encrypt the bootstrap vault before installing Argo CD or Headlamp:

```bash
cp infra/vault.yml.example infra/vault.yml
ansible-vault encrypt infra/vault.yml
just complete
```

Vault lifecycle helpers are available through `just`:

```bash
just vault-status
just vault-encrypt
just vault-edit
just vault-decrypt
```

`vault-encrypt` initializes `infra/vault.yml` from the example when it is
missing. Prefer `vault-edit` for routine changes because `vault-decrypt` leaves
secrets in plaintext until the file is encrypted again.

The encrypted vault stores the GitHub ↔ Argo CD webhook shared secret,
optional read-only Git credentials, and the fine-grained token used to create
or update the repository webhook. The Argo CD initial administrator password
and Headlamp login token are not stored in Vault.

Retrieve the initial Argo CD administrator password with:

```bash
just argocd-credentials
```

This connects to `master01`, runs `kubectl get secret
argocd-initial-admin-secret` with `/etc/kubernetes/admin.conf`, and decodes the
password. It therefore works only after `just cluster` and `just gitops` have
completed. The current automation-controller instance does not need Kubernetes
or `kubectl` installed. `just gitops` or `just complete` applies the
Vault-managed webhook secret to `argocd-secret` and synchronizes it to GitHub.

Create or rotate `webhook.github.secret` independently with:

```bash
just generate-webhook-secret
just vault-edit
# Set vault_argocd_webhook_secret to a random value of at least 32 characters.
just argocd-webhook-secret
```

`generate-webhook-secret` prints a 256-bit value from `openssl rand -hex 32`.
Paste it into the encrypted Vault as `vault_argocd_webhook_secret`. The apply
command then patches the Argo CD secret and creates or updates the GitHub
repository webhook with the same shared secret.

If GitHub webhook access fails, verify that `gitops_repository_slug` is exactly
`OWNER/REPOSITORY` and that `vault_github_webhook_token` is authorized for that
repository with repository Webhooks read/write. The Argo CD administrator
password is generated by Argo CD and is deliberately absent from Vault;
retrieve it with `just argocd-credentials`.

Run `just github-webhook-access` to verify authentication, repository access,
and Webhooks API access independently without printing the token.

The mapping is `ci01 → master01`, `quality01 → master02`,
`artifacts01 → worker01`, and `agent01 → worker02`. No clone or EC2 creation
step is required.

Project 2 uses its own inventory, credentials, lifecycle, and clean machines.

