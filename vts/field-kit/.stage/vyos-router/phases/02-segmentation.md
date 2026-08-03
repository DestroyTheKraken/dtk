# Phase 02 — Segmentation checklist (base job)

Apply what the **customer hardware allows**. Not every Deco/Starlink setup gets full VLANs.

## Goals

- [ ] Separate guest Wi‑Fi from trusted LAN when supported
- [ ] Isolate IoT / smart home where practical
- [ ] Disable UPnP if not required
- [ ] Document admin URL and who holds the password
- [ ] Change default admin password if still factory
- [ ] Note DHCP range and any static reservations (printers, NAS)

## If custom VyOS appliance (Add-on B)

- [ ] HOME vs GUEST/IOT zones per your template
- [ ] WAN NAT + basic firewall
- [ ] Management access limited (LAN admin / Tailscale as designed)
- [ ] **Do not** install k3s on the router
- [ ] Netdata only as **container** when monitoring sold

## Done when

Client devices work; guest cannot reach private shares (spot-check); notes in inventory.
