# Project 01 — Ansible DevOps Tooling

This repository provisions four AWS EC2 virtual machines and configures one
service responsibility per host:

| Host | Purpose |
| --- | --- |
| `ci01` | Jenkins controller |
| `quality01` | SonarQube and PostgreSQL |
| `artifacts01` | Nexus Repository |
| `agent01` | Dedicated Jenkins build agent |

This repository is a self-contained implementation.

After Project 1 evidence and backups are complete, the same four instances can
be handed to Project 2 without changing the Project 1 security group. Run
`just transition-project2 transition-project2` to attach a separately tagged,
self-referencing Kubernetes security group to their primary network interfaces.
The transition is guarded and validates the exact four Project 1 instances.

## Prerequisites

- Python 3 and Ansible Core on the control machine
- AWS credentials supplied through the normal AWS SDK credential chain
- An existing VPC and subnet
- An EC2 key pair and its matching local private key
- Four preallocated Elastic IPs in the target region, each with the configured
  `Name` tag

Do not commit AWS credentials, private keys, Vault passwords, or generated
inventory containing sensitive connection data.

## Configure

1. Copy `inventories/dev/group_vars/all/main.yml.example` to
   `inventories/dev/group_vars/all/main.yml`.
2. Replace every `CHANGE_ME` value.
3. Install collections:

   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

## Automation with just

Install `just` and the operating-system Python venv package, then use the
project recipes:

```bash
sudo apt install just python3-venv
just doctor
just setup
just key-init
just vault-encrypt
just validate
just deploy
```

Run `just --list` to see individual provisioning, deployment, verification,
inventory, reset, and guarded destruction actions. Set another target
environment with `TARGET_ENVIRONMENT=test just deploy`.

Vault helpers prompt for the password and never store it in the Justfile:

```bash
just vault-status
just vault-encrypt
just vault-view
just vault-edit
just vault-decrypt
```

Prefer `just vault-edit` for routine secret changes because the file remains
encrypted at rest. `just vault-decrypt` deliberately leaves a plaintext file
and should only be used when required.

`just key-init` creates the local EC2 SSH key only when it is missing. During
provisioning, Ansible imports the matching public key into AWS under
`aws_key_name`; the private key never leaves the controller.

## Provision

```bash
ansible-playbook playbooks/00-provision.yml
ansible all -m ansible.builtin.ping
```

Provisioning is tag-based and idempotent. Each instance receives the ownership
tag `Project=devops-g12-p1` and an environment tag. The playbook discovers the
four preallocated Elastic IPs by their exact `Name` tags, associates them with
the matching instances, and writes those stable addresses to the generated
inventory. It fails rather than allocating an address when a configured EIP is
missing or duplicated.

## Destroy

First inspect the selected resources:

```bash
ansible-playbook playbooks/99-destroy.yml \
  -e target_environment=dev \
  -e confirm_destroy=false
```

The inspection run deliberately fails after printing its target list. Destroy
only after confirming that list:

```bash
ansible-playbook playbooks/99-destroy.yml \
  -e target_environment=dev \
  -e confirm_destroy=true
```

Only EC2 instances matching both the project and environment tags are eligible.
Destroying instances detaches the Elastic IPs but leaves them allocated so a
later provisioning run can associate the same addresses with replacements.

## Deploy and verify

After provisioning and DNS configuration:

```bash
ansible-playbook playbooks/10-bootstrap.yml --ask-vault-pass
ansible-playbook playbooks/20-services.yml --ask-vault-pass
ansible-playbook playbooks/30-edge-https.yml --ask-vault-pass
ansible-playbook playbooks/40-verify.yml --ask-vault-pass
```

`playbooks/site.yml` runs provisioning through verification in dependency
order. See `docs/operations/runbook.md` for reset, backup, recovery and evidence
commands.

