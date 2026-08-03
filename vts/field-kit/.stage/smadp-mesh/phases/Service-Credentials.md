---
tags: [security, credentials, bitwarden, grokos, smadp]
date: 2026-07-08
status: active
owner: Josh
---

# Service Credentials — SMADP

> [!warning] Security
> **Do not store live passwords in this vault file.** Secrets live on disk only (`~/.config/sovereign/`, k8s Secrets, `~/.grok/`).  
> Use this doc as a **catalog + rotation guide**. Export the CSV block below into Bitwarden (Import → CSV).

---

## Where secrets live

| Service | On-disk location | k8s Secret (if any) |
|---------|------------------|---------------------|
| Nextcloud admin | `~/.config/sovereign/nextcloud.env` → `NEXTCLOUD_ADMIN_PASSWORD` | `nextcloud/nextcloud` |
| MariaDB app user | `nextcloud.env` → `MARIADB_PASSWORD` | `nextcloud/nextcloud` |
| MariaDB root | `nextcloud.env` → `MARIADB_ROOT_PASSWORD` | Helm values at deploy |
| VyOS SSH | `~/.config/sovereign/vyos.env` | — |
| Grok / xAI API | `~/.grok/auth.json` | — |
| restic backup | `~/.config/sovereign/restic.env` → `RESTIC_PASSWORD` | — |
| Tailscale HTTPS cert | `/var/lib/smadp/tailscale-certs/` | `nextcloud/nextcloud-tailscale-tls` |

**Retrieve Nextcloud admin password:**
```bash
grep NEXTCLOUD_ADMIN_PASSWORD ~/.config/sovereign/nextcloud.env
# or
kubectl get secret nextcloud -n nextcloud -o jsonpath='{.data.nextcloud-password}' | base64 -d; echo
```

---

## Credential catalog

| Service | URL / Host | Username | Password source | Notes |
|---------|------------|----------|-----------------|-------|
| Ubuntu SSH | `kraken@um690` / node1 / node2 | `kraken` | SSH key (no password login) | [[phases/Phase-0-Foundation]] |
| Tailscale admin | https://login.tailscale.com/admin | Google/Microsoft SSO | SSO provider | Enable MagicDNS + HTTPS certs |
| Tailscale mesh | `*.taile52ad9.ts.net` | — | Pre-auth keys per device | [Admin keys](https://tailscale.com/kb/1085/auth-keys) |
| Nextcloud | https://um690.taile52ad9.ts.net | `admin` | `nextcloud.env` | Android app uses same URL |
| MariaDB (internal) | `nextcloud-mariadb` svc | `nextcloud` | `nextcloud.env` | Not exposed outside cluster |
| k3s API | `https://100.120.232.39:6443` | — | `/etc/rancher/k3s/k3s.yaml` | Tailscale-only |
| Longhorn UI | via kubectl port-forward | — | no default auth | [Longhorn security](https://longhorn.io/docs/1.6.0/deploy/accessing-the-ui/) |
| Traefik dashboard | `/dashboard/` on ingress host | — | no auth (mesh only) | [Traefik dashboard](https://doc.traefik.io/traefik/operations/dashboard/) |
| VyOS router | `192.168.20.1` SSH | `vyos` | `vyos.env` | um690 only |
| Grok Build / xAI | terminal + https://console.x.ai | xAI account | `~/.grok/auth.json` | [Grok Build docs](https://docs.x.ai/build/overview) |
| Valley Tech site | https://um690.taile52ad9.ts.net/vts/ | — | no login (public) | Edit contact in `hugo.toml` |

---

## How to change passwords (official methods)

### Nextcloud admin
1. Web UI → **Personal settings** → **Security** → change password, or  
2. CLI: `kubectl exec -n nextcloud deploy/nextcloud -- su -s /bin/bash www-data -c 'php occ user:resetpassword admin'`  
3. Update `~/.config/sovereign/nextcloud.env` and Bitwarden.  
   Docs: https://docs.nextcloud.com/server/latest/admin_manual/configuration_user/reset_admin_password.html

### MariaDB (Nextcloud DB)
1. Rotate in MariaDB, then sync Helm secret + `nextcloud.env`.  
2. Docs: https://mariadb.com/kb/en/change-password/  
3. Re-run `bash scripts/phase2/deploy-nextcloud.sh` with updated env (backs up PVC data).

### Tailscale
- Admin console → **Settings** → rotate auth keys; re-auth devices as needed.  
  https://tailscale.com/kb/1081/reset-logins

### VyOS
- `set system login user vyos authentication plaintext-password <new>`  
  https://docs.vyos.io/en/latest/configuration/system/login-user.html

### Grok / xAI API
- Re-authenticate: run `grok` and sign in, or manage keys at https://console.x.ai  
  https://docs.x.ai/docs/build-overview

### Ubuntu / SSH
- Key rotation: add new key to `~/.ssh/authorized_keys`, remove old.  
  https://help.ubuntu.com/community/SSH/OpenSSH/Keys

---

## Bitwarden import (CSV)

Copy into a file `smadp-credentials.csv` and import in Bitwarden (**Tools → Import → Bitwarden csv**).  
Replace `REPLACE_ME` with values from on-disk secret files after import.

```csv
folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp
SMADP,,login,Nextcloud Admin,Generated at deploy; see nextcloud.env,,,https://um690.taile52ad9.ts.net,admin,REPLACE_ME,
SMADP,,login,MariaDB nextcloud,Internal cluster only; nextcloud.env,,,,nextcloud,REPLACE_ME,
SMADP,,login,VyOS Router,um690 SSH only; vyos.env,,,ssh://192.168.20.1,vyos,REPLACE_ME,
SMADP,,login,Tailscale Admin,SSO — no password stored,,,https://login.tailscale.com/admin,,,
SMADP,,login,xAI / Grok Build,API session in ~/.grok/auth.json,,,https://console.x.ai,,,
SMADP,,login,Ubuntu kraken@um690,SSH key auth — store key in Bitwarden Secure Note,,,ssh://um690.taile52ad9.ts.net,kraken,,
SMADP,,login,Ubuntu kraken@node1,SSH key auth,,,ssh://node1.taile52ad9.ts.net,kraken,,
SMADP,,login,Ubuntu kraken@node2,SSH key auth,,,ssh://node2.taile52ad9.ts.net,kraken,,
```

---

#sovereignaid #credentials #bitwarden #security