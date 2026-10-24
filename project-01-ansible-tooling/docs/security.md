# Security model

- AWS resources are selected by project and environment ownership tags.
- SSH is key-only, root login is disabled, UFW defaults to deny, and fail2ban
  is enabled.
- Jenkins, SonarQube and Nexus bind only to loopback; NGINX is the public edge.
- Secrets are loaded from an encrypted Ansible Vault file and sensitive tasks
  use `no_log`.
- The Jenkins controller runs no builds. `agent01` has a dedicated user and no
  Docker-group membership, so it cannot access a privileged Docker socket.
- Persistent named volumes are retained by service reset operations.
- Destruction requires exact tags, an allowed environment and an explicit
  confirmation after displaying instance IDs.

