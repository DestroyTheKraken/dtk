---
title: Destroy the Kraken — About Joshua Hickman
date: 2026-06-18
tags:
  - dtk
  - joshua-hickman
  - destroy-the-kraken
aliases:
  - DTK
  - Destroy the Kraken
---

# Destroy the Kraken

**Joshua Hickman** — portfolio, homelab journal, and rural IT services  
**Based in:** Omak, Washington (Okanogan County)  
**Portfolio:** [github.com/DestroyTheKraken](https://github.com/DestroyTheKraken)

---

## Why the Name

### Hello and welcome. First — why "Destroy the Kraken"?

The idea is simple: defeat what looks like an utter impossibility. **The Kraken.**

When I decided to change careers from pastoral care to IT and systems administration, the weight of it hit all at once. Full pivot. New field. New credentials. New everything. And the internal voice was loud: *This is impossible at my age, at this stage of life.*

**That's the Kraken** — the myth you build in your head that tells you the gap is too wide, the water too deep, the creature too big.

**Destroy it anyway.**

That's what this brand is about — personally and professionally.

### Why it fits rural client work (even in Omak)

The name sounds unusual next to "local Starlink help." I get that. But the metaphor maps directly to what my clients face:

- *"Starlink will never work reliably on this property."*
- *"There's no way to get whole-house WiFi through these hills."*
- *"Private cloud is too complicated for a home or small farm."*

**That's their Kraken.** My work is to survey the problem honestly, build a clear plan, and deliver systems that actually work — documented, tested, and supportable.

### Where I'm headed (career)

The long-term target is clear: **Systems Administrator** at one of the Elon Musk family of companies — xAI, Tesla, Starlink, Boring Company, or SpaceX.

That's not a vague dream. It's a direction with a timeline and documented work behind it. Every lab build, every certification, and every client engagement is a deliberate step on that path.

This project closes the gap — one solved problem, one earned credential, one deployed system at a time.

---

## Who I Am

I'm **Joshua Hickman** — Army veteran, live music performer, audio engineer, former pastor, and career-changer turned IT professional based in **Omak, Washington**.

My background isn't a straight line, and I've stopped apologizing for that.

### Audio and systems thinking (20+ years)

I spent twenty years performing live music and ten years as a freelance audio engineer across Texas, primarily in the Austin area. That work taught me systems thinking before I had a word for it:

- Signal flow and gain staging
- Troubleshooting under pressure with an audience watching
- Calm, fast diagnosis when there is no margin for error

During the same period I consulted for churches on turnaround and process improvement for worship and music departments — volunteer training, leadership development, and technical education on live sound and studio systems. I wrote custom technical manuals for church sound technicians: detailed, purpose-built documentation I handed off without keeping copies. I didn't yet understand the value of what I was building. **Documentation is now non-negotiable in everything I deploy.**

### Military and ministry

Army service gave me operational discipline, exposure to enterprise-scale systems, and respect for process under pressure. Years in **pastoral ministry** sharpened clear communication, leading people through complexity, and meeting them where they are. Both reinforced what audio work had already started.

### Today

- Rural IT and private infrastructure work in Omak and Okanogan County
- Background in wireless and fiber support, networking, and client-facing technical service
- Operating and documenting a **four-node production cluster** (um690 + node1/2/3) that mirrors what I deploy for premium clients
- Building an **AI-co-designed LFCS learning program** (AIOS) while studying for certification
- Selective engagements for career-changers who want the same AI-augmented systems path I am walking

The non-linear path wasn't a detour. **It was training.**

---

## How I Learn and Build

**I build real systems at the edge of what I know today.** Linux fundamentals and a self-hosted cluster are my foundation. **Grok Build** and strict runbooks help me implement faster. I reference AI chat when I hit a gap — and I **can repeat the process**.

| I do myself | AI helps with |
|-------------|---------------|
| Linux ops, Docker deploys, cluster verification | Learning program structure (AIOS daily schedule, guides) |
| Vendor doc research (Cloudflare, Docker, Nextcloud) | Business positioning and service packaging |
| Runbook writing and following | Site content and automation script generation (Grok Build) |
| Honest capability audits before I sell a service | Resume framing, industry navigation, outreach drafts |

Full methodology: [[BUILD_METHODOLOGY]].

---

## What I Build (Production Cluster)

My proving ground is a **four-node Tailscale mesh** on Starlink — the same architecture I offer clients as **ValleyForge**.

| Node | Tailscale | Role |
|------|-----------|------|
| **um690** | 100.81.13.95 | Control plane — monitoring, ops portal, deploy scripts |
| **node1** | 100.75.124.36 | App worker — Nextcloud (ValleyHub), portfolio site, Redis |
| **node2** | 100.104.54.20 | Edge gateway — Traefik, Cloudflare tunnel, NATS |
| **node3** | 100.82.177.52 | Storage — PostgreSQL, MinIO |

### Network foundation

- Starlink in IP passthrough mode
- TP-Link Deco M3 mesh (trusted + IoT segments)
- Tailscale tailnet for admin access; Cloudflare Tunnel for public hostnames (no open inbound ports)

Lab inventory and network notes: [DestroyTheKraken/homelab](https://github.com/DestroyTheKraken/homelab).

---

## Career Navigation

AI-assisted research and honest self-assessment shaped my targets: **Systems Administrator** at xAI, Tesla, Starlink, SpaceX, or Boring Company. Every lab build, client engagement, and documented deployment is a deliberate step — not a performance of skills I don't have yet.

The portfolio proves **orchestration and reproducibility**, not senior web-development pedigree.

---

## Client Services

Local and regional work in **Omak, Okanogan, and surrounding areas**. Full packages and pricing: see [[Content_Master]].

**Premium offering — ValleyForge Production Cluster ($2,950 labor):**

- 1 control plane + 3 worker nodes (client hardware or guided purchase)
- Tailscale mesh, Docker Compose stacks, Traefik + Cloudflare Tunnel
- Nextcloud + monitoring baseline, full runbooks, handoff training
- Repeatable process — I built mine the same way

**ValleyForge Premium ($3,850):** everything above plus **AI-augmented systems coaching** — help you replicate my learning program, career navigation workflow, and documented build method so you can extend the cluster yourself.

**Also available:**

- IT consulting and support (on demand or retainer)
- ValleyNet / ValleyHub / ValleyCare tiered services

### How I choose clients

I'm intentional about who I work with. The right fit is someone who knows what they want upfront, or is willing to define it with me before work starts. I do not begin without a **written, signed start-to-finish plan**.

Client work I accept must advance my craft and my career. At this stage of the journey, most rural IT engagements do exactly that — real systems, real documentation, real results.

---

## What This Site / Project Is

| Audience | What they need | Where |
|----------|----------------|-------|
| **Local clients** | Starlink, Nextcloud, rural IT packages | `index.html` (this repo) |
| **Recruiters / engineers** | Resume, lab notes, project walkthroughs | [GitHub](https://github.com/DestroyTheKraken) |
| **You (Obsidian)** | Full story, SSOT, outreach notes | This vault — `DTK_About.md`, [[Content_Master]] |

The portfolio is proof of **how I turn foundations + AI-assisted runbooks into live infrastructure**. GitHub holds the runbooks and the lab write-up.

**Portfolio site includes:**

- Honest build walkthrough (Linux, cluster, Grok Build, documentation)
- Project showcases with source linked on GitHub
- Premium ValleyForge offering for clients who want this cluster

Everything documented here is current and real. No filler.

---

## Let's Connect

**Local IT / Starlink / Nextcloud:**  
Call or text **509.557.7298** (business Google Voice) · contact form on client landing page

**Recruiters, engineering managers, collaborators:**  
[joshua.hickman1@gmail.com](mailto:joshua.hickman1@gmail.com) · GitHub: [DestroyTheKraken](https://github.com/DestroyTheKraken)

**Fellow career-changers or homelab builders:**  
I'm documenting this publicly so the journey helps someone else too. You're welcome here.

---

## Related notes

- [[Content_Master]] — marketing copy, packages, pricing (Single Source of Truth)
- [[BUILD_METHODOLOGY]] — honest build method and ValleyForge scope
- [[Free-Audit-Conversation-Script]] — private outreach script (not on public site)
- `index.html` — client-facing landing page
- `guides/` — setup and deployment steps