#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INVENTORY="$ROOT_DIR/infra/kubespray/inventory/project02/hosts.yml"
SOURCE_KUBECONFIG="$ROOT_DIR/infra/kubespray/inventory/project02/artifacts/admin.conf"
PYTHON="$ROOT_DIR/infra/.venv/bin/python"

test "$#" -gt 0 || { echo "Usage: $0 COMMAND [ARG ...]" >&2; exit 2; }
test -s "$INVENTORY" || { echo "Missing generated inventory; run 'just inventory'." >&2; exit 1; }
test -s "$SOURCE_KUBECONFIG" || { echo "Missing kubeconfig; run 'just cluster'." >&2; exit 1; }

eval "$("$PYTHON" - "$INVENTORY" <<'PY'
import shlex
import sys
import yaml

data = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))["all"]
host = data["hosts"]["master01"]
values = {
    "SSH_HOST": host["ansible_host"],
    "API_PRIVATE_IP": host["ip"],
    "SSH_USER": data["vars"]["ansible_user"],
    "SSH_KEY": data["vars"]["ansible_ssh_private_key_file"],
    "SSH_COMMON_ARGS": data["vars"].get("ansible_ssh_common_args", ""),
}
for key, value in values.items():
    print(f"{key}={shlex.quote(str(value))}")
PY
)"

temporary_dir="$(mktemp -d)"
tunnel_pid=""
cleanup() {
  if [[ -n "$tunnel_pid" ]]; then kill "$tunnel_pid" 2>/dev/null || true; fi
  rm -rf -- "$temporary_dir"
}
trap cleanup EXIT INT TERM

local_port="$($PYTHON - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"

cp "$SOURCE_KUBECONFIG" "$temporary_dir/admin.conf"
"$PYTHON" - "$temporary_dir/admin.conf" "$local_port" <<'PY'
import sys
import yaml

path, port = sys.argv[1:]
with open(path, encoding="utf-8") as stream:
    config = yaml.safe_load(stream)
config["clusters"][0]["cluster"]["server"] = f"https://127.0.0.1:{port}"
with open(path, "w", encoding="utf-8") as stream:
    yaml.safe_dump(config, stream, default_flow_style=False)
PY
chmod 600 "$temporary_dir/admin.conf"

read -r -a ssh_common_args <<< "$SSH_COMMON_ARGS"
ssh "${ssh_common_args[@]}" -i "$SSH_KEY" -o ExitOnForwardFailure=yes \
  -N -L "127.0.0.1:${local_port}:${API_PRIVATE_IP}:6443" \
  "${SSH_USER}@${SSH_HOST}" &
tunnel_pid=$!

for _ in {1..30}; do
  if nc -z 127.0.0.1 "$local_port" 2>/dev/null; then break; fi
  kill -0 "$tunnel_pid" 2>/dev/null || { wait "$tunnel_pid"; exit 1; }
  sleep 1
done
nc -z 127.0.0.1 "$local_port" 2>/dev/null || { echo "Kubernetes API tunnel did not become ready." >&2; exit 1; }

KUBECONFIG="$temporary_dir/admin.conf" "$@"
