# Nextcloud hub — START (your steps only)

**What you get:** Nextcloud on this Linux machine; real files stay in `/home/you/...` via outward symlinks; phone access via Tailscale.

## Where the “phase docs” are

| You look for      | What it actually is                                                         |
| ----------------- | --------------------------------------------------------------------------- |
| `phase-docs/`     | **Empty until install runs.** Fills with JSON + passwords *during* install. |
| Phase **guides**  | `phase-docs/PHASE-GUIDE.md` + `docs/INSTALL.md`                             |
| Phase **scripts** | `phase-01-scan-host.sh` … `phase-06-backup-automation.sh` (in this folder)  |

## Before

- Ubuntu/Mint-style desktop or server, internet, sudo user.  
- Tailscale recommended before or right after install.

## Your steps

1. Open this folder on the target PC:

```bash
cd /media/$USER/Ventoy/field-kit/nextcloud
# or wherever you copied the kit
```

2. Install (asks username, password, sudo once):

```bash
bash install.sh
```

3. Tailscale (if not already):

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

4. Phone: Tailscale on → Nextcloud app → URL printed by installer  
   (often `https://<hostname>.<tailnet>.ts.net`).

5. Save passwords from `phase-docs/.install-credentials` into your password manager, then delete that file from the USB copy if present.

**Done when:** phone sees Documents/Photos; PC still uses normal Home folders.

**Debug (optional):** `bash phase-01-scan-host.sh` then 02…06 in order; `bash verify-install.sh`.

## Household multi-user (optional)

If the PC has **several Linux logins** and each person should have their own Nextcloud + phone:

```bash
# After base install; on the hub with sudo
sudo ADMIN_USER=joshua bash ../local-mirror/nextcloud/configure-multiuser-hub.sh
# or: packages/nc_install/configure-multiuser-hub.sh
```

- **Same server URL for everyone** (e.g. `https://hickles.taile52ad9.ts.net`)
- **Username** = Linux login name  
- Full steps: `field-kit/docs/MULTIUSER-HUB.md`
