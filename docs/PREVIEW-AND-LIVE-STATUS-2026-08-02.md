# DTK website — gruvbox portfolio + message modal (2026-08-02)

| Field | Value |
|-------|--------|
| **Design** | Material **gruvbox soft dark** · simple portfolio |
| **Public live** | https://www.destroythekraken.com/ |
| **Scrubbed preview** | http://um690.taile52ad9.ts.net:8765/ |
| **Source** | `~/DTK/site/` → `/home/kraken/www/destroythekraken/` |
| **Contact** | Modal form → Formspree `xwvjdqdj` → **DTK Proton** (dashboard) |
| **Phone CTA** | Secondary: 509.557.7298 (call/text after connect) |

---

## Contact flow (Josh preference)

1. Visitor **messages** (name + phone + note)  
2. Formspree emails **Proton**  
3. **You call them back** to schedule remote/video  
4. Optional: text on business GV after you’re connected  

### Spam / bot blockers (site + Formspree)

| Layer | What |
|-------|------|
| Honeypot `_gotcha` | Hidden field; bots that fill it fail silently |
| Timing trap | Modal must be open ≥2.5s before submit |
| Math captcha | Random sum required |
| Phone sanity | Digits length check |
| Formspree built-in | Spam filtering |
| **You should enable** | reCAPTCHA **or** Cloudflare Turnstile in Formspree |
| **You should set** | Domain restrict to `destroythekraken.com` + www |
| **You should set** | Notification email = DTK Proton address |

Proton address is **never** printed in HTML (PII policy).

---

## Theme

- CSS: `theme.css` — **Controlled Chaos** (void `#050510`, purple/cyan/pink neon; not Tailwind CDN)
- HTML links: `theme.css?v=20260802cc` (query bust — CF once cached bare `/theme.css` as `application/octet-stream`)
- nginx ConfigMap `destroythekraken-nginx`: explicit `location ~* \.css$` → `text/css`
- **Not Tailwind:** Aug-2 portfolio pass replaced Tailwind+Alpine with plain HTML + `theme.css`. Old Tailwind pages remain under `site/dist/www/` and `www/destroythekraken.bak-*` only.
- `publish.sh` now copies `*.css`, `js/`, `blog/` (was HTML-only — CSS could be dropped on publish)

---

## APIs / AIDE_OS

See `~/AIDE_OS/docs/ops/API-USAGE-GROK-AND-FEEDS-2026-08-02.md`  
(Grok Build vs xAI API; Tab Stacked MSN needs product name clarified.)
