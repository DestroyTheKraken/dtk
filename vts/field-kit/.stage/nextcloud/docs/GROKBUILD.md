# GrokBuild project notes

Honest record of how **nc-lin-cs** was developed with **Grok** (xAI) in Cursor — what I drove vs what the assistant implemented.

## What I brought (from my prompts and decisions)

These reflect **my** operational skill and intent, not the model's:

- **Architecture I already wanted:** laptop-as-hub, outward symlinks (not duplicate storage), Tailscale-only HTTPS, inotify + cron, JSON phase docs for remote support.
- **Field workflow:** phased install → debug one phase → then single `install.sh`; USB kit on build machine, not left on client laptops.
- **Test discipline:** document every iteration; wipe and retest; don't ship until mobile sync shows all folders.
- **Platform reality:** Ubuntu 26.04 / PHP 8.5 / NC 33 discovered in lab — I pushed for one installer that adapts, not per-machine fix scripts.
- **Distribution thinking:** tarball + `curl -fsSL` like Tailscale; repo naming for future `nc-win-*` / `nc-deb-s` variants.
- **Product framing:** Sovereign NC field install for ValleyForge customers.
- **UX catches:** Termius `tail -f` looked like a hang — I asked; installer should auto-start watcher and use `/tmp/watch.log`.
- **SOP clarity:** I rejected `export NC_USERNAME` as customer steps; wanted interactive username/password in phase 1.
- **Security:** no passwords in committed JSON; anonymized test logs; private repo.

I am **not** claiming I wrote every Bash line by hand. I **am** claiming the requirements, test hosts, failure analysis, and accept/reject on each approach came from my side of the session.

## What Grok / Cursor did (assistant role)

- Implemented and refactored `nc_install` v2 patchwork into **v3** with phase-1 `install_plan`.
- Ran SSH checks on lab machines when keys allowed; used wipe via sudoers during retests.
- Fixed bugs from **my pasted terminal output** (e.g. Phase 01.01 JSON capture, verify false-fail on `config.php` permissions).
- Wrote and reorganized docs, anonymized test JSON, tarball/`install-nc-hub.sh` scaffolding.
- Synthesized lessons from Ubuntu 26.04 failures (NC33 flat `localstorage.allowsymlinks`, Apache :8080, symlink guardian).

## How to describe this publicly

> I designed and field-tested a phased Nextcloud hub installer for Debian laptops. Development was **GrokBuild-assisted**: I specified architecture, ran installs on real machines, validated phone sync, and directed phased vs one-command workflow. Grok helped implement scripts, docs, and debug from my terminal logs.

That is accurate and does not oversell AI or undersell the work of real installs and iteration.

## Tooling

- **Grok** in Cursor (agent mode, SSH to lab machines)
- **Test profiles:** Mint 24.04 reference, Ubuntu 26.04 bleeding-edge validation
- **Build machine:** canonical source, USB builds, optional remote backup pull

## What I still own going forward

- Customer-facing runbooks and pricing (ValleyForge)
- GitHub repo hygiene and releases
- Whether to merge into DTK monorepo or keep `nc-lin-cs` standalone
- Security review before public `curl | bash` without pinned checksums

---

*Last updated: 2026-06-21 — security sanitization + credential hardening.*
