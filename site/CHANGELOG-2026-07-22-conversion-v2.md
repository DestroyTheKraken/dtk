# Site conversion / cohesion pass v2 — 2026-07-22

**Scope:** `site/index.html`, `site/lab-notes.html`  
**Goal:** Raise conversion and trust for Okanogan County rural market without diluting Destroy the Kraken voice.

## Path: problem → free check-in → packages

| Change | Why |
|--------|-----|
| **Who it’s for** strip (homes/shops, STRs, farms, small operators) right after hero | Scannable market fit before long copy |
| Package **chooser** (“pick what you feel”) above cards | Cuts decision friction; routes to right package or free check-in |
| Dual links under problem (packages + free check-in) | Surfaces both paths earlier |
| Free check-in leads with “not sure what to buy?” | Problem-first for undecided readers |
| CTA label standardized: **Schedule Your Free Check-in** (not “Audit”) | Matches lead magnet naming; less formal/enterprise |
| Mid-page CTA: “lowest-risk next step” | Soft close after packages |

## Wording & honesty

| Change | Why |
|--------|-----|
| Hero: rural independence + Valley Tech Support as delivery line | County character + clear brand hierarchy |
| Softened “24 hours” → local priority / ~a day when warranted, **not a 24/7 SLA** | Matches SERVICE-MENU honesty; avoids overpromise |
| Problem bullets: label + benefit (Dead rooms, Terrain wins, etc.) | Skimmable for rural readers |
| AIDE card: anti-hype frame (“not AI-powered everything”) | Non-technical clarity without watering product |
| Quiet Watch combo note under packages | Best-effort, not 24/7, stays visible |
| Contact intro: free check-in if unsure | Reinforces primary conversion path |

## Structure & UX

| Change | Why |
|--------|-----|
| Nav: **How We Work** (replaces Why Local in primary nav) | Jump to process proof; why-local still on page |
| **How a job runs** 4-step section (scope → survey → build → handoff) | Trust without enterprise theater |
| Projects / why-local tightened | Less scroll weight after conversion core |
| Modal close → `closeModal()` + body scroll lock | Better mobile modal UX |
| Package chooser state on root `siteData` (not nested Alpine) | Buttons can open modals / contact |

## lab-notes.html

| Change | Why |
|--------|-----|
| Headline: “Documented, not a mystery box” | Reinforces ownership promise |
| Nav: Packages + Free Check-in | Clean path back to conversion |
| Valley Tech Support named under DTK | Brand cohesion |
| Package list: all six thematic names + one-line outcomes | Aligns with homepage menu |
| CTA block: free check-in + packages (dual) | Same conversion path as home |

## Unchanged (intentionally)

- Package names, price bands, technical claims (Nextcloud, Tailscale, Starlink/mesh, not an ISP)
- Thematic package set: Unstick, Rural Link, Private Hub, Quiet Watch, AIDE  
- **Private Hub (later same day):** folded IoT + private cloud (Nextcloud/Jellyfin/RetroArch) + home theater/audio into one A/V+IoT service
- Formspree form fields and contact phone
- HickMedia installer paths (not touched)
- Long-form about story (Kraken origin)

## Publish

```bash
bash ~/DTK/site/publish.sh
```

Review live: https://www.destroythekraken.com/ and `/lab-notes.html`
