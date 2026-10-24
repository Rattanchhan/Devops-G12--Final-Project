#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELM_VERSION="$($ROOT_DIR/.venv/bin/python - "$ROOT_DIR/versions.yml" <<'PY'
import sys
import yaml
print(yaml.safe_load(open(sys.argv[1], encoding="utf-8"))["helm_version"])
PY
)"
INSTALL_DIR="$ROOT_DIR/bin"
HELM="$INSTALL_DIR/helm"

if [[ -x "$HELM" ]] && [[ "$($HELM version --template '{{.Version}}')" == "$HELM_VERSION" ]]; then
  exit 0
fi

case "$(uname -m)" in
  x86_64) architecture=amd64 ;;
  aarch64|arm64) architecture=arm64 ;;
  *) echo "Unsupported Helm architecture: $(uname -m)" >&2; exit 1 ;;
esac

temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT
archive="helm-${HELM_VERSION}-linux-${architecture}.tar.gz"
curl --fail --location --silent --show-error \
  "https://get.helm.sh/${archive}" --output "$temporary_dir/$archive"
curl --fail --location --silent --show-error \
  "https://get.helm.sh/${archive}.sha256sum" --output "$temporary_dir/$archive.sha256sum"
(cd "$temporary_dir" && sha256sum --check "$archive.sha256sum")
mkdir -p "$INSTALL_DIR"
install -m 0755 "$temporary_dir/linux-${architecture}/helm" "$HELM" 2>/dev/null || {
  tar -xzf "$temporary_dir/$archive" -C "$temporary_dir"
  install -m 0755 "$temporary_dir/linux-${architecture}/helm" "$HELM"
}
