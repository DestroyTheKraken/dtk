# 00 — Start Here (Read This First)

This folder has **numbered guides** in order. Do them one at a time.

| Guide | What it does |
|-------|----------------|
| **00** (this file) | Big picture — what to do and in what order |
| **01** | Set up your contact form (Formspree) |
| **02** | Edit your website file (`index.html`) — phone, links |
| **03** | **Go live** — complete Cloudflare setup so the public can view your site |

---

## Content documents (Obsidian vault)

| File | Purpose |
|------|---------|
| **`DTK_About.md`** | Full story — why the name, biography, homelab, career, client philosophy |
| **`BUILD_METHODOLOGY.md`** | Honest build method — Linux, cluster, Grok Build, ValleyForge offering |
| **`Content_Master.md`** | Single Source of Truth — client marketing copy, packages, pricing |
| `notes/` | Private outreach notes (not on the public website) |
| `index.html` | Client-facing landing page (built from Content_Master) |

Sync this entire `/home/kraken/Projects/DTK/` folder to your local Obsidian vault.

---

## What you already have

Your public website is **`index.html`**. Supporting files:

| File / folder | Purpose |
|---------------|---------|
| `img/` | Your photos (headshot, mountains) |
| `.env` | **You create this** — holds your Cloudflare token (Guide 03) |
| `docker-compose.yml` | Puts the site online (Guide 03) |

---

## Your checklist (do in this order)

- [ ] **Guide 01** — Create a free Formspree account and connect the contact form
- [ ] **Guide 02** — Open `index.html` and replace Google + Facebook footer links
- [ ] **Guide 03** — Finish Cloudflare tunnel + `.env` + deploy (site live on the internet)

You do **not** need to understand HTML deeply. Each guide tells you **exactly what to find** and **exactly what to paste**.

---

## Do you need `/design` or `/execute-plan`?

**For this website: No. Skip both.**

| Command | What it is for | Do you need it now? |
|---------|----------------|---------------------|
| `/design` | Plans a **large** multi-step software project and writes a design document with a PR Plan | **No** — your landing page is already built |
| `/execute-plan` | Builds that multi-step plan automatically using git branches and code review | **No** — only run this **after** `/design` produces a design doc |

### When you WOULD use `/design` then `/execute-plan`

Use them later **only if** you want something bigger, for example:

- A customer login portal
- Online booking / scheduling
- A blog with an admin panel
- Multiple pages with a backend database

**If that day comes:**

1. Run `/design` and describe what you want built.
2. Wait until Grok finishes and gives you a **design document** (a `.md` file with a `## PR Plan` section).
3. **Then** run `/execute-plan` on **that design document** — not on `01-DKT-Web.md`.

Example (future):

```
/design I need a booking system for audit appointments with email confirmations
```

Wait for the design doc path, then:

```
/execute-plan /home/kraken/Projects/DTK/path-to-design-doc.md
```

---

## Quick preview (optional — see your site on your computer)

Open a terminal and run:

```bash
cd /home/kraken/Projects/DTK
python3 -m http.server 8080
```

Open a browser to: **http://localhost:8080**

Press `Ctrl+C` in the terminal when you are done previewing.

---

## Next step

- Finished Guides 01–02? Open **Guide 03**: `guides/03-go-live-cloudflare.md`
- Just starting? Open **Guide 01**: `guides/01-set-up-contact-form.md`