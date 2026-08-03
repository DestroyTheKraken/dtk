#!/usr/bin/env bash
# Lightweight sanity check for package presence
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for f in DESIGN.md INSTALL.md install.sh parent/docker-compose.yml; do
  [[ -f "${ROOT}/${f}" ]] || { echo "MISSING ${f}"; exit 1; }
done
echo "smoke-base: package files OK"
