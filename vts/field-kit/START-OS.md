# OS install from Ventoy — START (your steps only)

**ISOs on this stick (root):**

| ISO | Use |
|-----|-----|
| `ubuntu-26.04-live-server-amd64.iso` | Server / appliance base |
| `ubuntu-26.04-desktop-amd64.iso` | Desktop |
| `kubuntu-26.04-desktop-amd64.iso` | KDE desktop |
| `pop-os_24.04_...iso` | Pop!_OS desktop |
| `elementaryos-8.1-...iso` | Elementary |
| `Rocky-10.2-x86_64-dvd1.iso` | Rocky Linux |
| `vyos-2026.06.24-...iso` | Router OS → use `vyos-router/START.md` |

## Your steps

1. Plug USB; power on target; enter boot menu (often F12 / F10 / Esc).  
2. Choose **Ventoy** → select the ISO → boot.  
3. Complete that distro’s installer (disk, user, password).  
4. Reboot; remove USB when done.  
5. Install updates; install Tailscale if the job needs remote access.

**Done when:** you can log into the new OS.
