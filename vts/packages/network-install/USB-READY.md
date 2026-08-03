# USB — VyOS router kit (v2)

## On the stick today

| Path | Role |
|------|------|
| `valley-tech-network-install/` | Provisioner, templates, lab/onsite docs, optional Netdata add-on |
| Official **VyOS ISO** | **>>> YOU must add** (download from VyOS; not shipped in our tarball) |

## Recommended stick layout

Use **Ventoy** (or similar): drop `vyos-*-amd64.iso` + this folder on the stick.

```
INSTALLERS/
  vyos-1.x.x-generic-amd64.iso     ← YOU add
  valley-tech-network-install/     ← our package
```

## Workflows

1. **Lab:** boot ISO → install VyOS → run `provision/interactive-provision.sh` → paste config → label → ship.  
2. **Onsite:** plug cables (`onsite/PLUG-AND-PLAY.md`).  
3. **Monitoring:** only if sold; use parent/child docs separately.

## Secrets

- Do **not** leave live Netdata stream keys on the stick long-term.  
- Telegram stays on um690 only.
