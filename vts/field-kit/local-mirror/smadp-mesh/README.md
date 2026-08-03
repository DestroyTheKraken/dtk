# aide_installer_pkg

Portable copy of SMADP install scripts and manifests (**Phases 0–6**).  
**Maintained artifact** — refresh after every script change:

```bash
bash ~/SovereignAid/aide_installer_pkg/sync-from-repo.sh
```

| File | Purpose |
|------|---------|
| [[INSTALL]] | Concise numbered install steps (0–6) |
| [[Documents/valley-tech-support/field-kit/local-mirror/smadp-mesh/PROMPT]] | Grok Build bootstrap prompt |
| `sync-from-repo.sh` | Copy latest scripts/k8s from parent repo |
| `MANIFEST.txt` | File list (auto-generated) |

| Docs (in parent repo) | Purpose |
|-----------------------|---------|
| [[user-guide/README]] | Daily operations |
| [[user-guide/Services]] | All service URLs |
| [[phases/Build-Complete]] | Build summary |

Scripts: `scripts/` · Kubernetes: `k8s/` · User guide: `../user-guide/`

#sovereignaid #aide-installer-pkg