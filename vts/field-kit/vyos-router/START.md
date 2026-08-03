# VyOS router — START (your steps only)

**What you get:** 3-port router — WAN (`eth0`) + LAN1 trusted (`eth2`) + LAN2 guest/IoT (`eth3`).

**Config files on this kit:**

| File | Use |
|------|-----|
| `configs/config.boot.from-router-LATEST` | **Your live lab/home router** (best first test) |
| `configs/config.boot.home` | Simplified home template |
| `configs/config.boot.office` | Simplified office template |

## A) Install VyOS (once per appliance)

1. Keyboard + display on the mini-PC; plug **this Ventoy USB**.  
2. Boot menu → **Ventoy** → `vyos-2026.06.24-...iso`.  
3. Log in if asked (`vyos` / `vyos` on live image — follow on-screen).  
4. Install to internal disk (VyOS install menu / `install image`).  
5. Reboot from **internal disk** (not USB).  
6. Log in as `vyos` with the password you set during install.

## B) Load config (your steps on the router)

1. Plug Ventoy USB back in (if unplugged). Find it:

```text
ls /media/vyos
# or
ls /media
```

2. Enter config mode and load (adjust path if the USB label differs):

```text
configure
load /media/vyos/Ventoy/field-kit/vyos-router/configs/config.boot.from-router-LATEST
commit
save
exit
```

If `load` errors on a path, try:

```text
find /media -name 'config.boot.from-router-LATEST' 2>/dev/null
```

Then `load` that full path.

3. Set a strong password:

```text
configure
set system login user vyos authentication plaintext-password 'YOUR-STRONG-PASSWORD'
commit
save
exit
```

4. Power off. Label ports: **WAN eth0 | LAN1 eth2 | LAN2 eth3**.

## C) Onsite cables

1. Modem/Starlink → **WAN**.  
2. Trusted switch/AP → **LAN1**.  
3. Guest/IoT switch/AP → **LAN2**.  
4. Power on.  
5. Phone on trusted Wi‑Fi: IP `192.168.10.x`, internet works.  
6. Phone on guest: IP `192.168.20.x` or `192.168.50.x` (depends which config you loaded), internet works.

**Done when:** both LANs get DHCP and internet; you can SSH from um690 if allowed in that config.

**Note:** Live export uses HomeNet `.10` + LabNet `.20`. Product “guest” templates use `.50` for LAN2 — check which file you loaded.
