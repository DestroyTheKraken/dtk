# Field kit phone & business call routing

**Status:** planned / confirm hardware in morning when aios-field-kit is charged.  
**Do not publish Tailscale IPs or device serials on the public website.**

## Business number

| Field | Value |
|-------|--------|
| **Public business line** | **509.557.7298** (Google Voice) |
| **Role** | DTK / Valley Tech Support business calls only |
| **Not used for** | Personal cell traffic (keep personal number private) |

## Tailnet devices (current map)

From `tailscale status` (as of last check):

| Hostname | Tailnet IP | Platform | Notes |
|----------|------------|----------|--------|
| **aios-field-kit** | `100.106.44.126` | Android | Offline ~16d — charge + reconnect to confirm model |
| **j-phn** | `100.100.196.29` | Android | Online when last checked — intended **call-forward target** |

### Hardware hypothesis (confirm when online)

- **aios-field-kit:** believed **Samsung Galaxy A54+** (or A54) — verify Settings → About phone after charge/join tailnet.  
- **j-phn:** personal/work carry phone on tailnet (do **not** publish number on website).

## Desired call flow

```
Client dials 509.557.7298  (Google Voice — public business)
        │
        ▼
Google Voice routing / linked device
        │
        ├── rings / app on field device(s)
        │
        └── Forward / linked handset: prefer reachability on
            j-phn (100.100.196.29) when you want calls on the
            phone you carry; aios-field-kit is the dedicated
            field appliance (see roles below).
```

### Morning checklist (when aios-field-kit is charged)

1. Power on → unlock → join Wi‑Fi or cellular.  
2. Confirm Tailscale connected: should show as **aios-field-kit** / `100.106.44.126`.  
3. Settings → About phone → record exact model + Android version here.  
4. Install / open **Google Voice** app signed into the **business** Google account (same as 509.557.7298).  
5. In [Google Voice settings](https://voice.google.com/settings) (on a computer):  
   - Link devices that may ring  
   - Configure **forwarding** / linked numbers so calls reach the handset you want  
   - Prefer forwarding behavior so **j-phn** gets the call when you are mobile  
6. Test: call 509.557.7298 from another phone; confirm which device rings.

> Exact GV “forward to number” UI depends on account type. Use the business Google account only—never mix personal GV if you keep numbers separate.

## aios-field-kit role — “sovereign field phone”

Dedicated field appliance (not personal daily driver branding):

| Capability | Notes |
|------------|--------|
| **Business Voice** | Google Voice app for 509.557.7298 |
| **Tailnet** | Always-on Tailscale; manage as `aios-field-kit` |
| **Installers** | Offline/USB notes, bookmarks to `destroythekraken.com/hickmedia.sh` |
| **Tools / links** | Field kit URLs, VTS checklists (`~/DTK/vts`) |
| **Security keys** | Hardware keys / passkeys as you enroll them |
| **Notes / passwords** | Bitwarden (or preferred vault) — **not** plain notes with secrets |
| **Network analyzer** | Fing / Net Analyzer / similar + `tailscale status` / ping to lab |
| **Sovereign phone** | Prefer private apps, Tailscale-only admin, no unnecessary cloud backup of client data |

Ops tree for field content can grow under:

```text
~/DTK/field-kit/          # (create as needed)
~/DTK/vts/field-kit/      # existing VTS field kit
```

## Security

- Tailnet IPs in this file are **ops-only** (this repo path is for you, not the public site pack).  
- Do not put `100.x` addresses on destroythekraken.com.  
- Business GV number **may** appear on the public site (labeled business).  
- Personal phone number for j-phn: Bitwarden only.

## Update log

| Date | Note |
|------|------|
| 2026-07-21 | Documented IPs from tailscale status; aios-field-kit offline; confirm model when charged |
