# DNS outage: apex `destroythekraken.com` (2026-08-02)

## Symptom
Browser: `DNS_PROBE_POSSIBLE` / “This site can’t be reached” for **https://destroythekraken.com**

## Status (verified 2026-08-02 ~14:35 PDT)

| Host | DNS A/AAAA | HTTPS | Notes |
|------|------------|-------|--------|
| **www.destroythekraken.com** | ✅ Cloudflare anycast | ✅ **200** | Site + tunnel healthy |
| **destroythekraken.com** (apex) | ❌ **no records** | ❌ does not resolve | Authoritative: `NOERROR` / `ANSWER: 0` (NODATA) |

Tunnel connector: `cloudflared-dtk.service` **active** · tunnel id `7b9246da-f9f9-42d8-9e63-de98e98cb1cc`  
Remote tunnel ingress (from logs): **only** `www.destroythekraken.com` → `http://10.43.100.144:80`  
Local `~/.config/cloudflared/config.yml` lists both hostnames, but **token tunnels use Zero Trust dashboard config**, not that file.

Forcing apex via CF IP returns **HTTP 530** (hostname not routed on tunnel).

## Root cause (two missing pieces)
1. **DNS:** no A/AAAA/CNAME for bare `@` / `destroythekraken.com` in Cloudflare DNS.  
2. **Tunnel route:** Public Hostname for apex not added (only `www`).

k8s Ingress already has both hosts; origin nginx is fine. This is **Cloudflare edge config only**.

## Fix (dashboard — ~5 minutes)

### A) Add tunnel public hostname for apex
1. Open https://one.dash.cloudflare.com → **Networks** → **Tunnels**  
2. Open tunnel **dtk** / the DTK website tunnel (`7b9246da-…`)  
3. **Configure** → **Published application routes** / **Public Hostname**  
4. **Add** hostname:
   - **Subdomain:** leave empty (apex) *or* type `@`
   - **Domain:** `destroythekraken.com`
   - **Service type:** HTTP  
   - **URL:** same as www — `http://10.43.100.144:80`  
     (cluster Service IP for `destroythekraken` in `websites` ns; confirm with `kubectl -n websites get svc destroythekraken`)
5. Save. Confirm connector log shows config with **both** hostnames.

### B) Add DNS for apex (proxied)
1. https://dash.cloudflare.com → zone **destroythekraken.com** → **DNS** → **Records**  
2. **Add record:**
   - **Type:** CNAME  
   - **Name:** `@` (apex)  
   - **Target:** `7b9246da-f9f9-42d8-9e63-de98e98cb1cc.cfargotunnel.com`  
   - **Proxy status:** **Proxied** (orange cloud)  
   - Cloudflare will CNAME-flatten apex automatically  
3. Alternatively, from the tunnel Public Hostname UI, use **“Add a CNAME for this hostname”** / complete DNS if prompted.

Optional but recommended:
- Page Rule or Redirect Rule: `destroythekraken.com/*` → `https://www.destroythekraken.com/$1` (301) so one canonical host.

### C) Verify
```bash
dig +short destroythekraken.com A @1.1.1.1   # should return CF anycast IPs
curl -sSI https://destroythekraken.com/ | head -5
curl -sSI https://www.destroythekraken.com/ | head -5
```

Expect: apex resolves; HTTP 200 or 301→www. Not DNS_PROBE_POSSIBLE. Not 530.

## Immediate workaround
Use **https://www.destroythekraken.com** — works now.

## Why Grok cannot fix this from um690 alone
- Tunnel token only runs the connector; it does not edit zone DNS or Zero Trust hostname routes without a **Cloudflare API token** (DNS:Edit + account access).  
- No CF API token is configured in this seat for automated DNS.

## After fix
Update this file status line to **resolved** + date.  
Keep `config.yml` and Zero Trust ingress **in sync** (both `www` and apex).
