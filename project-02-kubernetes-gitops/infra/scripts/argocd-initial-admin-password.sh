#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INVENTORY="$ROOT_DIR/infra/kubespray/inventory/project02/hosts.yml"
PYTHON="$ROOT_DIR/infra/.venv/bin/python"

test -x "$PYTHON" || { echo "Run 'just setup' first." >&2; exit 1; }
test -s "$INVENTORY" || {
  echo "Missing generated inventory; run 'just inventory' first." >&2
  exit 1
}

eval "$("$PYTHON" - "$INVENTORY" <<'PY'
import shlex
import sys
import yaml

data = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))["all"]
host = data["hosts"]["master01"]
values = {
    "SSH_HOST": host["ansible_host"],
    "SSH_USER": data["vars"]["ansible_user"],
    "SSH_KEY": data["vars"]["ansible_ssh_private_key_file"],
    "SSH_COMMON_ARGS": data["vars"].get("ansible_ssh_common_args", ""),
}
for key, value in values.items():
    print(f"{key}={shlex.quote(str(value))}")
PY
)"

read -r -a ssh_common_args <<< "$SSH_COMMON_ARGS"
ssh "${ssh_common_args[@]}" -i "$SSH_KEY" \
  "${SSH_USER}@${SSH_HOST}" \
  "sudo kubectl --kubeconfig /etc/kubernetes/admin.conf \
    -n argocd get secret argocd-initial-admin-secret \
    -o 'jsonpath={.data.password}' | base64 -d; echo"
