#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBESPRAY_DIR="$ROOT_DIR/kubespray"
test -f "$KUBESPRAY_DIR/cluster.yml" || {
  echo "Vendored Kubespray source is missing: $KUBESPRAY_DIR" >&2
  exit 1
}
test -f "$KUBESPRAY_DIR/requirements.txt" || {
  echo "Vendored Kubespray requirements are missing." >&2
  exit 1
}
python3 -m venv "$ROOT_DIR/.venv"
"$ROOT_DIR/.venv/bin/pip" install --upgrade pip
"$ROOT_DIR/.venv/bin/pip" install boto3 botocore kubernetes passlib 'bcrypt==4.0.1'
"$ROOT_DIR/.venv/bin/pip" install --requirement "$KUBESPRAY_DIR/requirements.txt"
"$ROOT_DIR/.venv/bin/ansible-galaxy" collection install --requirement "$ROOT_DIR/requirements.yml"
"$ROOT_DIR/scripts/install-helm.sh"
