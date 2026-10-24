# Architecture decisions

## ADR-001: Two-member etcd baseline

The required four-node teaching topology initially places etcd on `master01`
and `master02`. Quorum is two, so losing either member prevents new writes.
This repository must not describe that baseline as fault-tolerant HA.

## ADR-002: GitOps separation

CI builds and scans the application image, pushes an immutable artifact, and
proposes a reviewed Git change. Argo CD performs deployment. CI receives no
permanent cluster-admin credential.

## ADR-003: Three repository responsibility split

Infrastructure automation lives at the project root and in `infra/`. The
repository-ready React source and CI path is
`ReactJS-Service-Pipeline-Deployment/`. Desired deployment state lives in the
repository-ready `argocd-gitops-repository/` path. CI may propose an immutable digest
change directly to the configured GitOps branch but has no cluster credential;
Argo CD has read-only Git access and reconciles the cluster automatically.

