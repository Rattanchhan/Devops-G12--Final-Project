# Operations runbook

## First deployment

1. Create `inventories/dev/group_vars/all/main.yml` from its example.
2. Create and encrypt `inventories/dev/group_vars/all/vault.yml`.
3. Confirm DNS records resolve to the three service hosts.
4. Install requirements and run `playbooks/site.yml`.
5. Rotate application bootstrap credentials and store recovery material outside Git.

The equivalent automated workflow is:

```bash
just doctor
just setup
just key-init
just vault-encrypt
just validate
just deploy
```

Use `just vault-edit` to change secrets while retaining encryption. Use
`just vault-view` for temporary inspection and `just vault-status` to verify
encryption. `just vault-decrypt` leaves secrets in plaintext until
`just vault-encrypt` is run again.

## Idempotence

Run the bootstrap, services and edge playbooks twice. The second run should
report no unexpected changes. Compose reconciliation preserves named volumes.

## Backup

Stop writes before backing up. Back up Jenkins `jenkins_home`, SonarQube's
database and named data volumes, and Nexus `nexus_data`. Encrypt backups, record
retention and regularly test restoration to disposable hosts.

## Reset services

Run `playbooks/50-reset-services.yml -e confirm_service_reset=true`. This
recreates containers but preserves volumes. Data deletion is deliberately not
implemented by that playbook.

With `just`, run `just reset-services reset-dev`.

## Destroy

Run `playbooks/99-destroy.yml` without confirmation to inspect exact instance
IDs. Only rerun with `confirm_destroy=true` after exporting required evidence
and backups.

With `just`, run `just destroy-plan`, inspect the IDs, then run
`just destroy destroy-dev`.

## Transition the existing VMs to Project 2

After exporting Project 1 evidence and backups, run:

```bash
just transition-project2 transition-project2
```

This discovers exactly the four tagged Project 1 instances, creates the
separately owned `devops-g12-p2-reuse` security group, permits traffic only
among members of that group, and attaches it to each primary network interface.
It preserves the original Project 1 security group and Elastic IPs.

## Evidence

Capture Ansible recap from two runs, HTTPS certificate details, container
health, Jenkins execution on `agent01`, SonarQube quality gate, Nexus publish
and download, package versions, backup restore, and guarded destroy output.

