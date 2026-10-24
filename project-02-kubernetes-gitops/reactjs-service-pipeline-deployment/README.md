# ReactJS Service Pipeline Deployment

This directory is intended to be published as the application repository.
The same React source is promoted through two protected branches:

- `dev` publishes an immutable image and writes its digest to
  `environments/dev` in the GitOps repository.
- `prod` publishes an immutable image and writes its digest to
  `environments/prod`.

The workflow runs install, lint, test, application build, container build,
registry push, registry pull verification, image scanning, and a direct GitOps
branch update. It never receives Kubernetes or Argo CD credentials.

Configure this GitHub repository with:

- optional variable `GITOPS_REPOSITORY`, defaulting to
  `Rattanchhan/argocd-gitops-repository`
- optional variable `GITOPS_BRANCH`: target branch, defaulting to `main`
- secret `GITOPS_TOKEN`: fine-grained token with Contents read/write on only
  the GitOps repository

Protect `dev` and `prod` and require the `quality` job. The configured GitOps
target branch must permit direct pushes by `GITOPS_TOKEN`.
