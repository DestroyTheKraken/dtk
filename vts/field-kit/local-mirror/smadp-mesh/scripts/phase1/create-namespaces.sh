#!/usr/bin/env bash
# create-namespaces.sh — SMADP k8s namespaces on um690
# Run on um690: sudo bash create-namespaces.sh

set -euo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

NAMESPACES=(nextcloud websites monitoring ops-center)

for ns in "${NAMESPACES[@]}"; do
    k3s kubectl create namespace "${ns}" --dry-run=client -o yaml | k3s kubectl apply -f -
    echo "  namespace/${ns}"
done

echo "Done."