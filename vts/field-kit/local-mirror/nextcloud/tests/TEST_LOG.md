# nc_install Test Log

Chronological record of installer test iterations. Each run appends via `verify-install.sh` or manual `nc_record_test_iteration`.

Host-specific details (names, IPs, tailnet DNS) are **not** stored here — see anonymized profiles in `tests/host-*.json`.

## Verified profiles

| Profile | OS | PHP | Nextcloud | Installer | Mobile sync |
|---------|-----|-----|-----------|-----------|-------------|
| host-mint24 | Mint / Ubuntu 24.04 | 8.3 | 30.0.5 | v2 live · v3 plan match | verified |
| host-ubuntu26 | Ubuntu 26.04 resolute | 8.5 | 33.0.5 | v2 + fixes · v3 consolidates | verified |

## Lessons incorporated into v3

1. **Ubuntu 26.04 (resolute):** ondrej/php PPA has no suite — use native PHP 8.5 + NC 33.0.5.
2. **NC 33 symlinks:** `occ config:system:set localstorage allowsymlinks` (nested) does not work at runtime — flat `localstorage.allowsymlinks` in `config.php` required.
3. **Apache backend:** Tailscale serve must proxy to `127.0.0.1:8080`, not port 80 alone.
4. **DB idempotency:** `DROP` + `CREATE` user on retry; full `rm -rf` data dir (not `rm data/*`).
5. **Mixed NC versions:** wipe `/var/www/nextcloud` before extract.
6. **Mobile app:** deleting top-level folders removes symlinks — 5-min guardian cron.
7. **bzip2:** required for `.tar.bz2` extraction — in phase 2 package list.
8. **Credentials:** passwords stored in `phase-docs/.install-credentials` (chmod 600), not phase JSON.

---

### host-mint24 — 2026-06-19 (v2 baseline)

- **Version:** 2.x
- **Status:** pass
- **Notes:** Reference deployment. PHP 8.3 + NC 30.0.5. Tailscale serve → :8080. Watcher + 2-min cron.

### host-ubuntu26 — 2026-06-20 iterations 1–4

- **Version:** 2.x → 2.x + symlink-guardian
- **Status:** fail → partial → pass
- **Notes:** NC 33 + PHP 8.5 pairing, flat symlink key, Apache :8080, guardian cron. See `host-ubuntu26.json`.

### host-mint24 — 2026-06-20 (v3 plan validation)

- **Version:** 3.0.0 (plan only — live install unchanged)
- **Status:** pass
- **Notes:** Phase 1 install_plan confirms PHP 8.3 + NC 30.0.5 + PPA use_ondrej_if_needed.

### host-ubuntu26 — install.sh one-command (v3.0.0) — PASS

- **After wipe:** single `bash install.sh` · ~5 min · no hung prompt
- **verify:** 10/10 · watcher auto-started → `/tmp/watch.log`

### host-ubuntu26 — Phased install COMPLETE (v3.0.0)

- **Phases 01–06:** all pass
- **Mobile sync:** all folders visible
- **verify-install:** config.php permission check fixed (sudo -n + occ fallback)

### host-ubuntu26 — Phase 01.01 (v3.0.0) — FAIL → fixed

- **Error:** `SyntaxError` writing `01-host-scan.json` — prompt text captured into `nc_username`
- **Fix:** Prompt text → stderr; `nc_username` written via `os.environ` in phase-01 Python block.
