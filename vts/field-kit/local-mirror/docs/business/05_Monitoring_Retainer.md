# Monitoring Retainer (Add-on) — Netdata + Telegram

**Date:** July 08, 2026  
**Status:** Approved product design  
**Related:** [[03_Services_Overview]] · `packages/network-install/`

---

## Positioning

Remote monitoring is an **optional add-on**, not part of base network install.

| Layer | Who | Tool |
|-------|-----|------|
| Central parent | You (um690 / Sovereign mesh) | Netdata Parent (Docker) |
| Per client | Always-on host or custom router appliance | Netdata child → streams to parent |
| Alerts | You | **Telegram** |

**Scale:** solo operator, **4–6 clients** max.

---

## Pricing (see also services overview)

| Item | Starter range |
|------|----------------|
| Setup (enroll + test alert) | $100–150 one-time |
| Monthly retainer | $75–150/month |
| Custom router appliance | Quoted separately (Add-on B) |

---

## What the client gets

- Host/router metrics visible on **your** Netdata parent (not a public customer portal by default)
- You receive **Telegram** alerts when critical health checks fire (e.g. host offline, disk critical)
- Best-effort response per service agreement (not 24/7 NOC)

## What they do not get (say this out loud)

- Base network job alone does **not** include monitoring
- No multi-tech on-call rotation
- No guarantee without an always-on host or custom appliance

---

## Always-on host rules

| Situation | Approach |
|-----------|----------|
| Client opts out of monitoring | No Netdata; **dilemma is moot** |
| Client wants monitoring + has always-on PC/NUC | Install Netdata child + Tailscale on that host |
| Client wants monitoring, no spare PC | Sell **custom VyOS (or similar) appliance** with Netdata container (upcharge) |
| Client refuses appliance and has no host | Do not sell monitoring add-on |

---

## Netdata on custom VyOS router (decision)

| Approach | Verdict |
|----------|---------|
| **k3s on the router** | **No.** Wrong workload for a firewall appliance (resources, attack surface, ops burden). |
| **Netdata as a VyOS container** (Podman / `set container` on VyOS 1.4+) | **Yes, supported pattern** on adequate x86 hardware. Community has run Netdata as a container on VyOS. Stream child → your parent. |
| **Custom appliance build** (VyOS + Netdata container, or hardened Debian router OS + Netdata) | **Yes — preferred sellable SKU** for monitoring clients without a spare PC. Upcharge covers hardware + image + install. |

**Hardware floor (practical):** enough RAM/CPU that routing + Netdata do not fight (prefer mini PC class x86, not underpowered plastic routers).

**MikroTik RouterOS:** native Netdata is not the path; if you ever use RouterOS gear, keep Netdata on a separate always-on host or stick to VyOS/Debian appliance SKU.

---

## Telegram

- Primary notification channel for all Netdata parent alerts
- Configure once on parent; verify with a forced offline test on every new client enroll
- Keep bot token and chat ID **out of git** (`~/.config/valley-tech/telegram.env` or Netdata health config on parent only)

---

## Consent

Remote access (Tailscale) and optional monitoring require signed agreement language in `04_Service_Agreement.md`. Client may revoke access anytime; remove child + Tailscale on request when offboarding.

---

#valley-tech-support #netdata #retainer
