# Port architecture (canonical)

**Three Ethernet ports only.** No fourth LAN.

| Role | Interface name (this build) | Hardware | Network |
|------|----------------------------|----------|---------|
| **WAN** | `eth0` | Built-in NIC (preferred for stability) | DHCP from ISP / Starlink |
| **LAN1** | `eth2` | USB-Ethernet | Trusted — Family (home) or Staff (office) `192.168.10.0/24` |
| **LAN2** | `eth3` | USB-Ethernet | Guest **and** IoT together `192.168.50.0/24` |

## Why not eth1?

On this appliance, the kernel named USB NICs **`eth2` and `eth3`** and **skipped `eth1`**. Templates match that reality. Do not add `eth1` unless `show interfaces` on a given box actually lists it.

## Home vs office (logical, not extra ports)

| Profile | LAN1 meaning | LAN2 meaning |
|---------|--------------|--------------|
| Home | Family / trusted | Guest + smart home / IoT |
| Office | Staff / trusted | Guest + IoT |

Same cables, same three ports; only labels and hostname differ (`config.boot.home` vs `config.boot.office`).

## Cable map (label the chassis)

```
[ ISP / Starlink ] -----> eth0  WAN   (built-in)
[ Trusted switch/AP ] --> eth2  LAN1  (USB)
[ Guest/IoT switch/AP ]-> eth3  LAN2  (USB)
```

## If another machine names NICs differently

1. Boot VyOS → `show interfaces`  
2. Copy the matching template  
3. Rename only the `ethernet ethX` blocks to match that hardware  
4. `load` → `commit` → `save`
