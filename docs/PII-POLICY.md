# PII / contact policy — DestroyTheKraken

## Business vs personal

| Kind | Example | Public site? | Installers? |
|------|---------|--------------|-------------|
| **Business Google Voice** | 509.557.7298 | **Yes** (labeled business) | **No** |
| Personal cell | (never publish) | **No** | **No** |
| Personal email | gmail/etc. | **No** (use Formspree) | **No** |
| DTK Proton (business inbox) | Formspree destination only | **No** (never print on site) | **No** |
| Home street address | | **No** | **No** |
| Tailscale IPs / hostnames | aios-field-kit, j-phn | **No** (ops docs only) | **No** |
| Tunnel tokens / secrets | | **No** | **No** |
| Professional name / headshot | Joshua Hickman | **Yes** (brand) | **No** (not needed in pack) |
| Service area | Omak / Okanogan | **Yes** | Optional |

## Business phone (public)

- **Number:** 509.557.7298  
- **Service:** Google Voice (business)  
- **Purpose:** Field client calls for DTK / Valley Tech Support  
- **Not** a personal handset number published as personal contact  

## Installers

`HickMedia/installer/pack-release.sh` still **fails the pack** if this phone (or personal email/secret patterns) appear in the **installer payload**.  
Clients install the product; they contact you via the **website**, not a number baked into the tarball.

## Private ops docs (not published on the website)

- Field-kit / call routing: `docs/FIELD-KIT-PHONE.md` (tailnet IPs, device roles)  
- Unredacted brand drafts: `brand/private/` (gitignored)
