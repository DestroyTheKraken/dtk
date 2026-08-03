# Apply a Valley Tech `config.boot` file (file-based, not bash-as-config)

## After VyOS is installed on the appliance

1. Plug **VTECHS** USB (or copy files via SCP).  
2. Mount USB (path varies; example):

```text
# Often something like:
ls /media/vyos/
```

3. In VyOS:

```text
configure
load /media/vyos/VTECHS/valley-tech-router/configs/config.boot.home
commit
save
exit
```

Office sites:

```text
load /media/vyos/VTECHS/valley-tech-router/configs/config.boot.office
commit
save
```

4. Change password:

```text
configure
set system login user vyos authentication plaintext-password 'your-strong-password'
commit
save
```

5. Label ports (**3 only**): **WAN eth0 (built-in) | LAN1 eth2 (USB) | LAN2 eth3 (USB)**  
   Home: LAN1=Family, LAN2=Guest+IoT · Office: LAN1=Staff, LAN2=Guest+IoT

## Edit for one client

1. Copy `config.boot.home` → `config.boot.smith-farm`  
2. Edit hostname, passwords, interface names if NICs differ  
3. `load` that file → `commit` → `save`  

Static IPs: add DHCP static-mappings in the file when needed — not in the default template.

## Why not “only replace file and reboot”?

Boot will load `/config/config.boot`, but **`load` + `commit` + `save`** is the supported way to validate and activate a new file while the system is running. Prefer that for lab provisioning.
