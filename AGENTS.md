# AGENTS — DestroyTheKraken (DTK)

## Identity

- **Brand:** DestroyTheKraken (DTK) — professional site, portfolio, installers.
- **Service line:** Valley Tech Support (`vts/`) — rural IT / network / media center jobs.
- **Product:** Sovereign Media Hub (`products/media-hub` → HickMedia).

## Working directory

Prefer **`~/DTK`** for brand + site + combined context.

| Path | Use |
|------|-----|
| `~/DTK` | Brand, website publish |
| `~/DTK/vts` | VTS ops (symlink to Documents/valley-tech-support) |
| `~/DTK/products/media-hub` | HickMedia installer (symlink) |
| `~/HickMedia` | Same media-hub repo (direct) |
| `~/valley-tech-support` | Same VTS tree (direct) |

## Public site

- URL: https://www.destroythekraken.com  
- Publish: `bash ~/DTK/site/publish.sh`  
- Tunnel: user unit `cloudflared-dtk.service` on um690  
- Do not break `/hickmedia.sh` or `/hickmedia/*` paths  

## Safety

- No secrets in git; exclude NAS `.env` / `.nc-hub-secrets`.  
- Phone/public contact on site is intentional marketing copy from Content_Master.  
