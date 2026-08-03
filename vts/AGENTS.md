# AGENTS — Valley Tech Support Ops

**Working directory:** `~/valley-tech-support` (canon).  
**Seat:** `kraken` on um690 · **one Grok / xAI account** (no separate vtech Grok login for now).

Also follow **`AGENT.md`** (teaching contract: plain language, copy-paste commands, prefer Grok does it).

## Focus
- Valley Tech **products and services** (packages, field kit, clients, overview docs).
- Do **not** derail into lab/desktop/cluster reorg unless Josh asks.
- Platform SMADP lives in `~/SovereignAid` — only touch when VTS work needs deploy/infra.

## Customer boundary
SSH/automation to customer gear only with **site + ticket ID** stated in the session.

## Paths
| Role | Path |
|------|------|
| Ops root | `~/valley-tech-support` |
| Field kit | `field-kit/` (+ USB via `assemble-to-usb.sh`) |
| Clients | `clients/<site-or-name>/` |
| Packages | `packages/` |
| NAS mirror (optional) | `/mnt/systems_admin/vtech/valley-tech-support/` |

## Secrets
Bitwarden only. Never write passwords into this tree or chat memory.
