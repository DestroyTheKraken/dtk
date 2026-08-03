# SMADP mesh (lab) — START (your steps only)

**What this is:** Scripts to rebuild **your** 3-node Sovereign mesh (um690 + workers), not a default client product.

**Do this only on lab machines you intend to wipe/rebuild.**

## Your steps

1. On **um690**, copy or open this folder (USB or repo):

```bash
cd /path/to/field-kit/smadp-mesh
# or: cd ~/SovereignAid && use aide_installer_pkg after sync
```

2. Read the one-page install list:

```bash
less INSTALL.md
```

3. Prerequisites **you** ensure first:  
   - Ubuntu on um690, node1, node2  
   - Tailscale on all three; MagicDNS on  
   - SSH keys work: `ssh node1` / `ssh node2`  
   - Grok CLI installed if you use delegation  

4. Run phases **in order** from um690 (each line needs you at the keyboard for sudo when prompted):

```bash
# From full SovereignAid tree preferred; if using this kit only:
bash scripts/phase0/verify-phase0.sh   # after foundation scripts
# Prefer full guide: ~/SovereignAid/aide_installer_pkg/INSTALL.md
```

**Practical path:** use **`~/SovereignAid`** as source of truth and this USB copy as backup. Follow numbered steps in `INSTALL.md` (prereqs → phase 0 → 1 → 2…).

5. After each phase, run the matching `verify-*.sh` before continuing.

**Done when:** `kubectl get nodes` shows three Ready nodes and services match `user-guide/Services.md`.

**Skip this kit** for normal Valley Tech client visits (use `vyos-router` + `nextcloud` instead).
