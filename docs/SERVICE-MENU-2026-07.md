# Destroy The Kraken — Service menu & delivery audit  
**Date:** 2026-07-22  
**Source of truth for capacity:** live um690 / k3s / Tailscale / Nextcloud / DTK site / VTS ops (not older marketing drafts)

---

## 1. Current Reality Check

### UM690 control plane (today)

| Item | State |
|------|--------|
| **Host** | `um690` · Ubuntu **26.04 LTS** · control-plane · LabNET `192.168.20.100` · Tailscale `100.120.232.39` |
| **Cluster** | k3s **3 nodes Ready** — um690 (control) + node1 + node2 |
| **Ingress** | Traefik healthy |
| **Storage** | Longhorn running (CSI provisioner has history of restarts — treat storage jobs as **careful**, not casual) |
| **Nextcloud** | **Running** (nextcloud + MariaDB + Redis) — proven private-cloud stack |
| **DTK site** | `websites/destroythekraken` + Cloudflare tunnel · https://www.destroythekraken.com |
| **VTS landing** | `websites/valley-tech-support` on MagicDNS (lab path) |
| **Docker (host)** | **Jellyfin** (healthy) · **netdata-parent** (healthy) |
| **NAS** | `/mnt/systems_admin` mounted · large durable store |
| **Ollama** | **inactive on um690 right now** — can still **install/teach** Ollama on client gear; don’t promise “AI runs on my cloud for free” |
| **AIDE** | **Product name** for private cloud + AI desktop environment (replaces ValleyForge public branding). AIDE_OS product R&D may stay on hold; **AIDE client service** is teach + build on **their** hardware |
| **AI CLIs (operator)** | Proven in daily work: **Grok Build**, plus experience with **Claude Code**, **Gemini CLI**, **OpenClaw**, **Ollama** — teach setup + prompting, not “we invent models” |
| **Related peers** | hickmedia (media hub reference), fam-media (MVP host), field phones on tailnet |

**Strengths you can stand on today:** real multi-node cluster, production Nextcloud path, Tailscale-first remote access, Netdata parent for monitoring *your* fleet, productized Media Hub installer (lab-proven), rural Starlink/network language backed by field kit (VyOS-style, guest/trusted LAN), local on-site presence in Omak/Okanogan.

**Constraints:** single primary operator; Longhorn/CSI not “set and forget” for client clusters; no 24/7 NOC; Starlink physical install skill must stay scoped to survey/optimize/configure (not structural mounting/permits unless you personally do that work every time); premium multi-node client cluster is high support surface.

### Claims inventory (current materials)

| Claim / offer | Where | Verdict |
|---------------|--------|---------|
| Starlink optimization package **$275** | Site + Content_Master | **Keep**, tighten exclusions (no tower work / no guarantee of ISP performance) |
| WiFi mesh optimization | Site | **Keep**, scope to consumer mesh (Deco-class) you actually deploy |
| Tailscale remote access | Site | **Keep** — core competency |
| Nextcloud private hub **$450–650** | Site | **Keep**, hardware client-owned; backups scoped |
| Bundle Starlink + Nextcloud **$650** | Site | **Keep** as optional combo |
| Retainer **$89/mo** “proactive Starlink monitoring” | Site | **Tighten** — best-effort, not SLA; requires always-on agent |
| **ValleyForge cluster $2,950** | Site | **Rename → AIDE** (Private Cloud Platform + AI Desktop Environment); re-scope — see Package E |
| **ValleyForge AI path $3,850** | Site | **Fold into AIDE** workflows + teaching tier — no separate “AI career package” name |
| Free 10–15 min audit | Site | **Keep** as lead magnet |
| “On-site within 24 hours when warranted” | About / master | **Soften** — “local priority when available,” not a guarantee |
| “Four-node production cluster same as clients get” | About | **Soften** — your lab proves *patterns*, not that every client gets a 4-node cluster |
| nc_install verified a-lap/hickles | Content_Master | **OK as method** if kit still works; don’t name client hosts publicly |
| Cleanroom drive recovery / enterprise AD / VoIP full stacks | Older service lists | **Do not advertise** |
| Local AI / Ollama for clients | Implied by stack interest | **Do not advertise** (inactive) |
| Media hub / HickMedia on public homepage installers | Removed from UI | **OK** — deliver as scoped add-on / private quote |
| General IT $75/hr · flats $150–250 | VTS overview | **Keep** |
| Network job $200–400 · VyOS 3-port appliance | VTS overview | **Keep** if you still pre-build appliances |
| Netdata monitoring add-on | VTS overview | **Keep** light — parent already runs on um690 |

---

## 2. Service menu (max 4 packages) — **publish these**

### Package A — **Kraken Unstick**  
*General IT / “make it work”*

| | |
|--|--|
| **Problem** | Broken PC, printer, login mess, slow machine, “I can’t get this to work.” |
| **Deliverables** | Diagnosis; fix or clear next-step plan; basic hardening (updates, remove obvious malware when in scope); short written notes of what changed |
| **Exclusions** | Data recovery from dead drives; illegal software; full business Microsoft 365 tenant design; multi-site fleets without a project quote |
| **Timeline** | Same day–2 days for single-device jobs |
| **Pricing** | **$75/hr** or **$150–250** flat for a named scope (e.g. “PC cleanup + printer”) |
| **Success metrics** | Client can complete the stated task; device boots/login works; issue closed or escalated in writing |
| **UM690 stack** | Optional Tailscale for remote assist after consent — not required for on-site |

---

### Package B — **Rural Link**  
*Starlink + Wi‑Fi + basic network order*

| | |
|--|--|
| **Problem** | Rural internet “works sometimes”; dead rooms; no guest network; nobody local who knows Starlink + mesh. |
| **Deliverables** | Site walk / signal notes; Starlink app checks + placement/alignment **guidance or hands-on within your safety skill**; consumer mesh (Deco-class or equivalent) channel/placement config; optional **trusted + guest/IoT** split if router appliance in scope; speed samples before/after (same devices/rooms); 1-page handoff (SSIDs, admin location, what not to touch); **30-day remote Q&A** (best-effort) |
| **Exclusions** | Structural tower work, roof work beyond your insurance/comfort, ISP outage guarantees, enterprise Wi‑Fi controllers, “unlimited devices” tuning, 24/7 monitoring (sold separately) |
| **Timeline** | ½–1 day on-site + remote prep |
| **Pricing** | **$275–400** fixed (use **$275** if single-building mesh; **$350–400** if + guest LAN appliance) · hardware pass-through |
| **Success metrics** | Written before/after speeds in agreed rooms; guest SSID isolated if sold; client can reconnect devices from handoff sheet |
| **UM690 stack** | Tailscale optional for later remote help; patterns from VTS field kit / home lab |

---

### Package C — **Private Hub**  
*Custom private cloud + IoT + home theater/audio on **their** hardware*  
*Leverages A/V engineering competency (20+ years) + IoT into **one** service offering (2026-07-22)*

**Positioning:** One package for systems the client owns — not separate “IoT” vs “media” SKUs. Quote tracks below; mix freely.

#### C1 — Private cloud & media services

| | |
|--|--|
| **Problem** | Files scattered across free clouds; wants ownership, on-prem media, living-room appliances without renting everything from big tech. |
| **Examples** | **Nextcloud** (files/photos/docs), **Jellyfin** (media library), **RetroArch** / living-room gaming frontends, Sovereign Media Hub patterns, Tailscale remote access |
| **Deliverables** | Install/configure on **client-owned** PC/NAS/mini-PC (Debian/Ubuntu family you support); HTTPS on LAN when applicable; **Tailscale** for remote access (no inbound port-forward required) when a server is in scope; backup job to **client storage** you document; training + runbook |
| **Exclusions** | You do **not** host their data on um690/Longhorn as a product; multi-site HA; unlimited users; email server; “set and forget forever”; off-site backup unless separately quoted |
| **Timeline** | 1–2+ days depending on stack (files-only shorter; media hub longer) |
| **Pricing** | **Entry files cloud $450–650** one-time · Jellyfin/RetroArch/full media hub **custom labor** (hardware client-owned) |
| **Success metrics** | Client can use the agreed apps without you; backup shows last success when sold; they can log in from agreed devices |
| **UM690 / product proof** | Live Nextcloud + Tailscale; HickMedia / media-hub installer patterns as process proof — not multi-tenant hosting |

#### C2 — Smart home & IoT configuration (formerly Package F)

| | |
|--|--|
| **Problem** | Wants cameras, lights, locks, speakers, thermostats, hubs that work together — without owning the research/order/deploy chaos. |
| **Ecosystems** | **Google Home/Nest**, **Apple HomeKit**, **Amazon Alexa** (+ compatible devices) |
| **Deliverables** | Consultation; research/shop/source/order; deploy & configure; naming/Wi‑Fi hygiene; handoff list; client **owns and pays for all equipment** |
| **Exclusions** | Josh does not own/rent devices; not an ISP; not unlimited redesign after handoff |
| **Pricing** | **Custom quote only** — contact form + consultation |
| **Success** | Devices online in agreed ecosystem; client can control daily use; ownership/accounts documented |

#### C3 — Home theater & audio (A/V engineering track)

| | |
|--|--|
| **Problem** | Living-room / theater setup is a mess — signal flow wrong, speakers placed poorly, sources fight each other, no clean handoff. |
| **Competency** | **20+ years A/V systems** (live music / audio engineering) applied to residential installs |
| **Deliverables** | Room goals & layout notes; source/display/receiver configuration; speaker placement guidance; cable/power hygiene; listening/functional checks; optional tie-in to private media servers and smart control; written “how this room works” card |
| **Exclusions** | Structural construction/permits beyond agreed scope; selling ISP service; unlimited redesign after handoff; guaranteeing cinema-grade results without matching budget/room |
| **Pricing** | **Custom quote** (often hourly or flat room scope) · equipment client-owned |
| **Success** | Client can switch sources and get expected picture/sound; handoff notes match reality |

---

### Package D — **Quiet Watch** (optional retainer)  
*Light care — not a NOC*

| | |
|--|--|
| **Problem** | “I don’t want to be the IT department after you leave.” |
| **Deliverables** | Best-effort remote response (business hours, agreed channel); agent on **their** always-on host to **your Netdata parent** (or equivalent) when sold; monthly or quarterly short health note; discounted hourly rate for extra work |
| **Exclusions** | **No** 24/7 SLA, no guaranteed response minutes, no full MSP stack, no monitoring without an always-on device |
| **Timeline** | Ongoing monthly/quarterly |
| **Pricing** | **$75–100/mo** or **$200–249/quarter** after a paid setup (**$100–150** if Netdata enroll is new) |
| **Success metrics** | Alert test succeeds once at enroll; client knows how to reach you; documented last check-in date |
| **UM690 stack** | **netdata-parent** already running on um690 |

### Combinations (allowed)

- **Rural Link + Private Hub** same engagement: **$650–900** depending on mesh/appliance — prefer **$650** only when both scopes are simple (document clearly).  
- **Unstick** never “includes free cluster.”  
- **Media hub / living-room PC** = private quote under Unstick or Link add-on (installer exists; public marketing optional).

### Package E — **AIDE**  
*Private Cloud Platform + AI Desktop Environment*  
*(formerly marketed as ValleyForge — consumer language, not DevOps jargon)*

**What AIDE means to a client (plain English):**  
A private place for their files and tools, plus a desk computer set up so AI assistants (chat/CLI tools they choose) work **reliably**, with habits that cut down bad answers — and enough Linux/command-line skill to stay productive in a text interface when that yields better results.

| | |
|--|--|
| **Problem** | “I want private infrastructure and AI tools that don’t invent nonsense — without becoming a full-time engineer.” |
| **Deliverables (choose track — can combine)** | See **E1** and **E2** below |
| **Exclusions** | You do **not** run their AI/cluster on um690 as multi-tenant hosting; no guarantee models are “hallucination-free”; no unlimited prompt support; hardware is **client-owned**; not a college degree or cert bootcamp |
| **UM690 proof** | You operate a live **k3s multi-node** mesh + Nextcloud + Tailscale; daily use of **Grok Build**; experience installing/using **Claude Code, Gemini CLI, OpenClaw, Ollama** |

#### E1 — **AIDE Desk** (AI Desktop Environment + workflows)

| | |
|--|--|
| **Exact problem** | Tools installed randomly; prompts are ad-hoc; outputs are unreliable; person is scared of the terminal. |
| **Deliverables** | Install/configure **one primary AI CLI or desktop stack** client chooses (from: Claude Code, Gemini CLI, Grok Build, OpenClaw, Ollama, or equivalent they already pay for); **Custom Workflows** pack (saved prompts/templates for *their* jobs); training on **structured prompting**; training on **orchestrated verification** (multi-step check: sources, constraints, re-ask, “prove it” loops) to **reduce** bad outputs; **Linux + command-line basics** for productive TUI work (navigation, files, editors, copy/paste, safe sudo habits); short written “how I work” card |
| **Exclusions** | Building them a multi-machine cluster (that’s E2); rewriting their whole business; unlimited monthly coaching without Quiet Watch or a block of hours |
| **Timeline** | 1–2 sessions (typically 4–8 hours total) |
| **Pricing** | **$450–750** one-time (or **$95/hr** for add-on hours) |
| **Success metrics** | Client runs a full task end-to-end with the chosen tool; can explain their verification steps; can complete 5 listed CLI tasks without you; workflows saved where they can find them |
| **Delivery confidence** | **High** for teaching + single-machine setup |

#### E2 — **AIDE Platform** (Private Cloud Platform + optimization)

| | |
|--|--|
| **Exact problem** | “I want a private cloud I control, set up cleanly, optimized for working with AI tools — not a mystery rack.” |
| **Consumer wording** | “We build and tune your **private cloud platform** — a small, private multi-machine setup on **your** gear, secured with private remote access, ready for your AI desktop tools.” |
| **Technical reality (ops, not client brochure)** | Deliver with **k3s** (what you run and know) or **microk8s-class** equivalent if client prefers Canonical path — **pick one stack per job and write it in the quote**. Same idea: small multi-node private mesh, not a hyperscaler. |
| **Deliverables** | Architecture for **client-owned** mini PCs/NAS (min nodes agreed in quote, often 1 control-style + 1–2 workers or a single stout node + storage); OS baseline; private network access (**Tailscale**); private apps baseline (e.g. files/Nextcloud-class if in quote); AI tool install path on the **desktop/admin machine**; **Sovereign AIDE setup & optimization** (harden defaults, updates path, resource limits so AI tools don’t melt the box); runbooks in **plain language** + optional deeper “under the hood” appendix; handoff training |
| **Exclusions** | 24/7 ops; “production bank-grade HA”; free infinite expansion; you as permanent co-admin; Longhorn multi-site DR without separate project; guaranteeing GPU cloud performance without their GPU hardware |
| **Timeline** | **3–10 days** wall-clock depending on hardware arrive + node count (not same-day) |
| **Pricing** | **$2,500–3,500** labor one-time (was ValleyForge ~$2,950 band) · hardware **client-paid** · **AIDE Desk** can add **+$400–600** if bundled in same project |
| **Success metrics** | All nodes healthy per handoff checklist; client accesses private services over Tailscale; client starts AI CLI on admin desktop; client can reboot a node and recover from the runbook |
| **Delivery confidence** | **Medium–high** if hardware is ready and scope is frozen; **use Delivery Checklist** every time — multi-node is still the heaviest offer |

#### E3 — **AIDE Coaching add-on** (prompting only)

| | |
|--|--|
| **Deliverables** | 2–4 hour block: structured prompting, verification loops, higher-yield patterns for their domain (docs, code, ops notes, client comms) |
| **Pricing** | **$200–400** flat or **$95/hr** |
| **Success metrics** | Client keeps a prompt library they created in-session; before/after sample on one real task |

### Still do not advertise

| Offer | Why |
|-------|-----|
| “We host your private cloud on our cluster” | Capacity + liability |
| “Zero hallucination AI” | Impossible claim — sell **reduction methods** only |
| Cleanroom recovery / full M365 tenant / VoIP as core | Not core menu |
| AIDE_OS as a separate unfinished product SKU | Keep R&D internal; client-facing name is **AIDE** service |

---

## 3. Branding & messaging (rural Central WA)

### Positioning (one sentence)

**Destroy The Kraken** helps homes and small operators in Omak and Okanogan County fix “impossible” tech problems — flaky rural internet, dead Wi‑Fi, and scattered files — with **local, documented systems you own**.

### Audience cues

Short-term rentals, realtors, tourism, small farms, home offices: **uptime, simple guest Wi‑Fi, private file access, someone local who shows up.**

### Tone rules

- Operator who **runs real infrastructure** (cluster, Nextcloud, Tailscale) — not “AI agency.”  
- Prefer: reliable, private, documented, local.  
- Avoid: “enterprise,” “AI-powered,” “revolutionize,” “unlimited,” “24/7,” “same 4-node cluster as my lab for every client.”

### Homepage messaging (ready to paste)

**Hero headline:**  
Rural IT that actually works in the hills.

**Subhead:**  
Starlink and Wi‑Fi that hold up. Private files on hardware you own. Clear docs — and a local person when something breaks.

**Primary CTA:**  
Book a free 15-minute network check-in  
**Secondary CTA:**  
See packages  

**About blurb (short):**  
I’m Joshua Hickman — Army veteran, long-time audio systems person, now building and fixing networks and private cloud for neighbors in Okanogan County. I run the same kinds of tools I install (Nextcloud, Tailscale, careful remote access). The “Kraken” is the voice that says it can’t be done. We destroy that with a survey, a plan, and a clean handoff.

**Trust lines (truthful):**  
- Local to Omak / Okanogan  
- Fixed-scope packages with written handoff  
- Remote access via Tailscale — no open house firewall ports required for Private Hub  
- Business line: 509.557.7298 (Google Voice)  

---

## 4. Website optimization recommendations

### Structure (keep maintainable)

1. **Hero** — problem + local + 2 CTAs  
2. **Who it’s for** — 3 bullets (home, rental, small business)  
3. **Packages** — only A–C (+ small note on Quiet Watch)  
4. **How we work** — survey → install → document → 30-day Q&A  
5. **About** — short bio (no career-to-xAI paragraph on homepage)  
6. **Contact** — form + business GV  

Remove or bury: ValleyForge pricing cards, AI career path package, installer curl blocks (already removed).

### Copy rewrites (key)

| Section | Do this |
|---------|---------|
| Packages | Replace 5–6 cards with **3** (+ retainer footnote) |
| Nextcloud | “On **your** always-on PC or NAS” — never “we host it for you on our cluster” |
| Retainer | “Best-effort remote check-ins” not “proactive monitoring of Starlink” without an agent |
| Audit | Keep free; rename **Network check-in** to avoid overselling “audit” |
| Footer | Keep Google Business link + business GV |

### Trust signals you can support

- Google Business profile link  
- Process: written handoff / before-after speeds for Rural Link  
- “I operate Nextcloud and Tailscale daily” (true)  
- Photos of **your** lab only if you’re willing — optional  

### UX

- Sticky nav: About · Packages · Contact (drop Installers from public)  
- One price range per card; “hardware extra” in small text  
- Mobile: CTA button always visible  

---

## 5. Delivery Confidence Checklist

**Before accepting a client or publishing a claim, answer every item. Any “No” = don’t sell or rewrite the scope.**

### Capacity

- [ ] I can complete this **within 14 days** of deposit without dropping other paid work.  
- [ ] I have **physical access** (or written remote consent) for the work.  
- [ ] Hardware is **client-owned or ordered** with clear who-pays rules.  
- [ ] If remote: client can install Tailscale / leave a host on.  

### Package fit

- [ ] Job maps to **Unstick / Rural Link / Private Hub (files and/or smart home) / Quiet Watch / AIDE (Desk or Platform)** only (or a one-page custom quote).  
- [ ] If **AIDE Platform**: hardware list frozen, stack choice (k3s vs microk8s-class) written, timeline ≥ multi-day accepted.  
- [ ] If **AIDE Desk**: single machine + one primary AI tool agreed; no “zero hallucination” language.  
- [ ] I am **not** promising ISP uptime, 24/7 SLA, or data recovery from failed disks.  

### Stack / skills

- [ ] For Private Hub: I have a **supported OS** path and backup target on-site.  
- [ ] For Rural Link: mesh/router gear is something I’ve configured before.  
- [ ] For Quiet Watch: always-on host exists **before** charging monthly.  
- [ ] um690/Netdata parent is healthy if monitoring is sold.  

### Risk / docs

- [ ] Written **inclusions / exclusions** emailed or signed.  
- [ ] Success metrics the client can verify are listed.  
- [ ] 30-day follow-up is **Q&A**, not free unlimited labor.  
- [ ] No personal cell or lab Tailscale IPs published to the client packet.  

### Honesty override

- [ ] If this fails at 2 a.m., **I** can recover it without inventing a new skill that night.

---

## Delivery risk still open (flag)

| Risk | Mitigation |
|------|------------|
| Public site **still shows ValleyForge $2,950 / $3,850** | **Update website packages ASAP** to the menu above |
| Longhorn CSI flakiness | Don’t sell client k3s/Longhorn lightly |
| Starlink physical mount liability | Scope to optimize/configure; use pro installer if roof/tower |
| Retainer without bandwidth | Cap clients; use Quiet Watch checklist |
| Single operator bus factor | Written runbooks; no “I’ll host everything for everyone” |

---

*End of audit. Next implementation step when you want it: rewrite live package cards on `~/DTK/site/index.html` to match this menu only.*

---

## Package F — **folded into Private Hub (C2)** — 2026-07-22

IoT / smart home is no longer a separate public package. Delivery details live under **Package C — Private Hub**, track **C2**.  
Prep fields on the contact form still collect smart-home ecosystem when relevant.

