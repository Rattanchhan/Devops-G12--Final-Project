# Architecture

The Ansible control node manages four ordinary EC2 VMs. This project contains
no Kubernetes control-plane or worker roles.

```text
Ansible controller
  ├── ci01          Jenkins controller       HTTPS: jenkins.<domain>
  ├── quality01     SonarQube + PostgreSQL    HTTPS: sonar.<domain>
  ├── artifacts01   Nexus Repository          HTTPS: nexus.<domain>
  └── agent01       Jenkins build agent       private agent connectivity
```

All resources are scoped by `Project=devops-g12-p1` and `Environment=<name>`.
Backend application ports will bind only to loopback or private container
networks. Only SSH from the controller and HTTP/HTTPS ingress are permitted by
the initial AWS security group.

Each host uses a preallocated Elastic IP selected by its exact `Name` tag. DNS
records point to these stable addresses. When an instance is replaced, Ansible
reassociates its existing Elastic IP and regenerates inventory from that
address; routine instance destruction does not release Elastic IP allocations.

