# Repository purpose

**https://github.com/DestroyTheKraken/nc-lin-cs**

Private professional toolkit — not a community open-source project.

## Who this is for

- **ValleyForge field installs** — canonical source for on-site laptop hubs
- **Client deployments** — USB kit, release tarballs, phased debug on target machines

## Who this is not for

- Upstream Nextcloud development
- Public contribution workflows or issue-driven roadmaps
- Anonymous `curl | bash` without review (use releases + checksum when client-facing)

## How I use it

| Workflow | Method |
|----------|--------|
| Day-to-day source | Clone/pull on build machine |
| Field visit | `package-release.sh` → USB tarball |
| Target machine | `bash install.sh` or phased debug |
| Version pin | Git tag `v3.0.0` + release asset |

## GitHub settings (recommended)

- **Visibility:** Private
- **Issues:** Off or personal notes only
- **Contributions:** Disabled — solo maintainer
- **Releases:** Attach `nc-lin-cs-X.Y.Z.tar.gz` + `.sha256` per field kit version

## Credentials on disk

- Never commit PATs, `phase-docs/`, or `.install-credentials`
- See [SECURITY.md](SECURITY.md) for full checklist

## Contact

ValleyForge — DestroyTheKraken GitHub org
