# ===== Proxmox / Dell OptiPlex NIC stability hardening =====
# Intel I219-LM (e1000e) mitigation checklist
# Run as root

# --- 1. Disable EEE and NIC offloads (runtime) ---
ethtool --set-eee eno1 eee off
ethtool -K eno1 tso off gso off gro off lro off

# --- 2. Persist e1000e driver stability options ---
cat <<'EOF' > /etc/modprobe.d/e1000e.conf
options e1000e InterruptThrottleRate=3000 IntMode=2
EOF

# --- 3. Disable SATA link power management ---
cat <<'EOF' > /etc/modprobe.d/ahci-no-lpm.conf
options ahci mobile_lpm_policy=0
EOF

# --- 4. Harden systemd against suspend/hibernate ---
mkdir -p /etc/systemd/logind.conf.d
cat <<'EOF' > /etc/systemd/logind.conf.d/ignore-sleep.conf
[Login]
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleSleepKey=ignore
HandlePowerKey=ignore
IdleAction=ignore
EOF

systemctl restart systemd-logind

# --- 5. Mask all sleep targets ---
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# --- 6. Kernel power / PCIe stability flags ---
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet nohibernate intel_idle.max_cstate=0 processor.max_cstate=1 pcie_aspm=off usbcore.autosuspend=-1"/' /etc/default/grub

update-grub

# --- 7. Rebuild initramfs ---
update-initramfs -uw

# --- 8. Example stable bridge configuration ---
# (edit /etc/network/interfaces manually if needed)
#
# auto vmbr0
# iface vmbr0 inet static
#     address 192.168.1.102/24
#     gateway 192.168.1.1
#     bridge-ports eno1
#     bridge-stp on
#     bridge-fd 2
#     post-up ethtool --set-eee eno1 eee off
#     post-up ethtool -K eno1 tso off gso off gro off lro off
#     post-up ethtool -s eno1 speed 1000 duplex full autoneg on

# --- 9. Enable persistent journaling ---
mkdir -p /var/log/journal
systemctl restart systemd-journald

echo "All mitigations applied. Reboot recommended."
