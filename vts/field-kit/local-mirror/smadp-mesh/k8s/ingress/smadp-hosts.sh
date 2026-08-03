#!/usr/bin/env bash
# smadp-hosts.sh — Tailscale MagicDNS hostnames (source from deploy scripts)
# MagicDNS provides {machine}.{tailnet} only — no service subdomains.

export SMADP_TAILNET="${SMADP_TAILNET:-taile52ad9.ts.net}"
export SMADP_CONTROL_HOST="${SMADP_CONTROL_HOST:-um690.${SMADP_TAILNET}}"
export SMADP_NODE1_HOST="${SMADP_NODE1_HOST:-node1.${SMADP_TAILNET}}"
export SMADP_NODE2_HOST="${SMADP_NODE2_HOST:-node2.${SMADP_TAILNET}}"