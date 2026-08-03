# Installer family naming

How I name Nextcloud installer repos when the **role** or **platform** changes.

## Recommended pattern

```
nc-{platform}-{role}
```

| Segment | Meaning | Examples |
|---------|---------|----------|
| `nc` | Nextcloud | fixed prefix |
| `platform` | OS / runtime | `lin`, `deb`, `win`, `docker` |
| `role` | What the kit installs | `cs`, `s`, `c` |

### Role codes

| Code | Meaning | Use when |
|------|---------|----------|
| **cs** | Client + server on one machine | Laptop hub — real folders + NC + phone sync (**this repo**) |
| **s** | Server only | Dedicated NC host; users are remote clients |
| **c** | Client only | Sync helper / desktop client config — no local NC server |

### Platform codes

| Code | Meaning |
|------|---------|
| **lin** | Linux (general Debian-family scripts) |
| **deb** | Debian/Ubuntu-specific variants (if `lin` splits later) |
| **win** | Windows (future — different toolchain entirely) |
| **docker** | Containerized stack (future — overlaps ValleyHub cluster) |

## Examples (future repos)

| Repo | Purpose |
|------|---------|
| `nc-lin-cs` | **This project** — laptop sovereign hub |
| `nc-lin-s` | Headless home server NC only |
| `nc-win-c` | Windows Nextcloud desktop client rollout script |
| `nc-deb-s` | Minimal Debian server image (no desktop symlinks) |

## Industry comparison

- **Discoverability:** GitHub search favors names like `nextcloud-laptop-hub-installer`. I use short `nc-lin-cs` internally; add a descriptive GitHub **description** and **topics**: `nextcloud`, `tailscale`, `self-hosted`, `installer`.
- **Versioning:** Keep version in **git tags** and tarball (`nc-lin-cs-3.0.0.tar.gz`), not in repo name.
- **Monorepo option:** Single `nc-installers` repo with `linux-cs/`, `linux-s/` subdirs — I split repos when release cadence or audience differs.

## My choice for GitHub

**`nc-lin-cs`** — clear enough for me across win/deb variants; document the matrix in this file so customers never see the abbreviation cold.