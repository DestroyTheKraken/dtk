#!/usr/bin/env bash
# Valley Tech network-install orchestrator
# Usage:
#   bash install.sh --phase base|monitoring|00|01|03|04|05|06|all-base|all-monitoring
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASES="${ROOT}/phases"

usage() {
  sed -n '2,5p' "$0" | tr -d '#'
  exit 1
}

run_phase() {
  local id="$1"
  case "${id}" in
    00|preflight) bash "${PHASES}/00-preflight.sh" ;;
    01|assess)    bash "${PHASES}/01-network-assess.sh" ;;
    02|seg)
      echo "Open and complete: ${PHASES}/02-segmentation.md"
      ;;
    03|handoff)   bash "${PHASES}/03-base-handoff.sh" ;;
    04|tailscale) bash "${PHASES}/04-tailscale-monitor-host.sh" ;;
    05|netdata)   bash "${PHASES}/05-netdata-child.sh" ;;
    06|verify)    bash "${PHASES}/06-verify-monitoring.sh" ;;
    base|all-base)
      bash "${PHASES}/00-preflight.sh"
      bash "${PHASES}/01-network-assess.sh"
      echo ">>> Complete segmentation checklist: ${PHASES}/02-segmentation.md"
      bash "${PHASES}/03-base-handoff.sh"
      echo "=== BASE JOB COMPLETE (no monitoring) ==="
      ;;
    monitoring|all-monitoring)
      bash "${PHASES}/04-tailscale-monitor-host.sh"
      bash "${PHASES}/05-netdata-child.sh"
      bash "${PHASES}/06-verify-monitoring.sh"
      echo "=== MONITORING ADD-ON COMPLETE ==="
      ;;
    *)
      echo "Unknown phase: ${id}" >&2
      usage
      ;;
  esac
}

[[ $# -ge 2 && "$1" == "--phase" ]] || usage
run_phase "$2"
