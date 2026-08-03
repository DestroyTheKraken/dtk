# phase-docs/ — runtime outputs (usually empty in the kit)

This folder is **not** missing documentation.

| What | Where |
|------|--------|
| **Human install guide** | `../docs/INSTALL.md`, `../nextcloud-install-guide.md`, `../START.md` |
| **Phase scripts** | `../phase-01-*.sh` … `../phase-06-*.sh` |
| **This folder** | Filled **during** install with JSON + credentials |

## What appears here after you run the installer

| File | Created by | Contents |
|------|------------|----------|
| `01-host-scan.json` | phase-01 | OS, user, disk, Tailscale, plan |
| `02-prereqs.json` | phase-02 | Packages installed |
| `03-nextcloud-core.json` | phase-03 | Paths, versions |
| `04-user-symlinks.json` | phase-04 | Symlink map |
| `05-complete.json` | phase-05 | Automation state |
| `.install-credentials` | install | **Passwords — keep private** (chmod 600) |

Until you run `bash install.sh` (or the phases in order), this directory stays **empty** on purpose.

It is listed in `.gitignore` so secrets and host scans are never committed to git.

See **PHASE-GUIDE.md** in this folder for what each phase does.
