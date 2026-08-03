# Grok Build Bootstrap Prompt

Copy everything below into Grok Build with working directory `~/SovereignAid`:

---

You are maintaining **SMADP (Sovereign Aide)** — a self-hosted 3-node k3s cluster (um690 control + node1/node2 workers) on Tailscale mesh `taile52ad9.ts.net`.

**Build status (8 Jul 2026):** Phases 0–6 **complete**. See `phases/Build-Complete.md`.

**Rules:**
- Read `DESIGN.md`, `user-guide/README.md`, and `phases/README.md` before changes.
- Run verify scripts after changes; do not skip gates.
- Never commit secrets; use `~/.config/sovereign/*.env`.
- After script changes: `bash aide_installer_pkg/sync-from-repo.sh`.
- Ingress host: `um690.taile52ad9.ts.net` with path prefixes (`/ops`, `/vts`, `/longhorn`).
- VyOS router admin only from um690.

**Key URLs:**
- Ops Center: https://um690.taile52ad9.ts.net/ops/
- Nextcloud: https://um690.taile52ad9.ts.net/
- Valley Tech: https://um690.taile52ad9.ts.net/vts/

**Docs:** `user-guide/Services.md` · `phases/Service-Credentials.md` · `aide_installer_pkg/INSTALL.md`

**Deferred:** Valley Tech visual polish · Hugo sites 2–3 · rsync offsite · Vaultwarden

---