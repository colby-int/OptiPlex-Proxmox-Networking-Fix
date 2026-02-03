# Proxmox / Dell OptiPlex NIC Stability Hardening

Fixes network interface dropouts and instability on Intel I219-LM (e1000e) NICs commonly found in Dell OptiPlex systems running Proxmox.

## Problem

The Intel I219-LM NIC can become unresponsive due to aggressive power management, Energy Efficient Ethernet (EEE), and hardware offload features conflicting with virtualization workloads.

## What This Script Does

1. **Disables EEE and NIC offloads** — Prevents the NIC from entering low-power states that cause packet loss
2. **Configures e1000e driver options** — Sets stable interrupt throttling and interrupt mode
3. **Disables SATA link power management** — Prevents storage-related hangs
4. **Disables system suspend/hibernate** — Ensures the server stays fully awake
5. **Masks sleep targets** — Prevents any sleep states via systemd
6. **Adds kernel boot flags** — Disables C-states, PCIe ASPM, and USB autosuspend
7. **Rebuilds initramfs** — Applies driver module changes
8. **Enables persistent journaling** — Helps diagnose issues after reboots

## Usage

```bash
# Run as root
chmod +x network_fix.sh
./network_fix.sh
reboot
```

## Requirements

- Proxmox VE (Debian-based)
- Root access
- Intel I219-LM or similar e1000e NIC

## Network Bridge Configuration

After running the script, edit `/etc/network/interfaces` to include stability settings:

```
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.102/24
    gateway 192.168.1.1
    bridge-ports eno1
    bridge-stp on
    bridge-fd 2
    post-up ethtool --set-eee eno1 eee off
    post-up ethtool -K eno1 tso off gso off gro off lro off
    post-up ethtool -s eno1 speed 1000 duplex full autoneg on
```

## Notes

- Replace `eno1` with your actual interface name if different
- A reboot is required for all changes to take effect
- Check logs with `journalctl -u systemd-networkd` if issues persist
