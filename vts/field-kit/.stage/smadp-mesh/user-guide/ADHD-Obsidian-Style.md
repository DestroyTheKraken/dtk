---
tags: [meta, style-guide, obsidian]
status: active
---

# ADHD-Obsidian Style Guide

> [!summary] TL;DR
> **Top = what matters now.** Short blocks. Checkboxes. Callouts. One screen = one idea.

---

## Rules (use on every vault note)

| Rule | Do this |
|------|---------|
| **TL;DR first** | `> [!summary]` callout — 1–3 lines max |
| **One next action** | `> [!todo] Next` with a single clear step |
| **Short sections** | `##` headers every 5–15 lines; no walls of text |
| **Checkboxes** | `- [ ]` for open; `- [x]` for done |
| **Callouts** | `summary`, `todo`, `tip`, `warning`, `success`, `note` |
| **Tables** | Reference data only — not prose |
| **Frontmatter** | `tags`, `date`, `status` on session notes |
| **Links** | `[[wikilinks]]` between vault notes |
| **Tags** | `#sovereignaid` `#phase0` at bottom for graph |

---

## Callout cheat sheet

```markdown
> [!summary] TL;DR
> One sentence.

> [!todo] Next
> - [ ] Do this one thing.

> [!tip]
> Optional shortcut.

> [!warning]
> Don't break this.

> [!success]
> Done when this is true.

> [!note]
> Context — skip if busy.
```

---

## Note template (copy for new notes)

```markdown
---
tags: []
date: YYYY-MM-DD
status: draft
---

# Title

> [!summary] TL;DR
>

> [!todo] Next
> - [ ]

---

## Context

(one short paragraph)

## Details

(bullets or table — not both unless needed)

---

#sovereignaid
```

---

## Session note template

```markdown
---
tags: [session, weekday]
date: YYYY-MM-DD
type: session-start
---

# Session — Day Date

> [!summary] TL;DR
> Resume GrokOS: [one line goal]

> [!todo] First command
> ```bash
> bash ~/SovereignAid/scripts/phase0/verify-ssh-mesh.sh
> ```

## Done last session
- [x]

## Do this session
- [ ]

## Paste into Grok
(copy block below horizontal rule)

---

#sovereignaid #session
```