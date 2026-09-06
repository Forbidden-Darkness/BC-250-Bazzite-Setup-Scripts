#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  Setup-32GB (Bazzite) – NexGen3D v1.5
#
#  Created By:  NexGen3D for the BC‑250
# ────────────────────────────────────────────────────────────────

echo "[●] Step 1/8: Stopping obsolete governor daemon services..." &&
(systemctl disable --now cyan-skillfish-governor 2>/dev/null || true) &>/dev/null &&
(systemctl disable --now cyan-skillfish-governor-tt 2>/dev/null || true) &>/dev/null &&
(systemctl disable --now oberon-governor 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 2/8: Enabling the filippor/bazzite COPR repository..." &&
(sudo copr enable filippor/bazzite -y 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 3/8: Cleaning and refreshing rpm-ostree metadata tracking..." &&
(sudo rpm-ostree cleanup -m 2>/dev/null || true) &>/dev/null &&
(sudo rpm-ostree refresh-md 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 4/8: Staging Enhanced Cyan Skillfish Governor SMU layers (This may take a minute)..." &&
(rpm-ostree install -y cyan-skillfish-governor-smu 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 5/8: Injecting performance flags into atomic kernel args (kargs)..." &&
(rpm-ostree kargs --append-if-missing=mitigations=off 2>/dev/null || true) &>/dev/null &&
(rpm-ostree kargs --append-if-missing=zswap.enabled=1 2>/dev/null || true) &>/dev/null &&
(rpm-ostree kargs --append-if-missing=zswap.max_pool_percent=25 2>/dev/null || true) &>/dev/null &&
(rpm-ostree kargs --append-if-missing=zswap.compressor=lz4 2>/dev/null || true) &>/dev/null &&
(rpm-ostree kargs --append-if-missing=systemd.zram=0 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 6/8: Tearing down old storage profiles and allocating 32GB BTRFS swap space..." &&
(sudo swapoff /var/swap/swapfile 2>/dev/null || true) &>/dev/null &&
(sudo rm -f /var/swap/swapfile 2>/dev/null || true) &>/dev/null &&
(sudo btrfs subvolume delete /var/swap 2>/dev/null || true) &>/dev/null &&
(sudo btrfs subvolume create /var/swap 2>/dev/null || true) &>/dev/null &&
(sudo semanage fcontext -a -t var_t /var/swap 2>/dev/null || true) &>/dev/null &&
(sudo restorecon /var/swap 2>/dev/null || true) &>/dev/null &&
(sudo btrfs filesystem mkswapfile --size 32G /var/swap/swapfile 2>/dev/null || true) &>/dev/null &&
(sudo semanage fcontext -a -t swapfile_t /var/swap/swapfile 2>/dev/null || true) &>/dev/null &&
(sudo restorecon /var/swap/swapfile 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 7/8: Finalizing persistent fstab maps and tuning virtual memory (swappiness=180)..." &&
(sudo sed -i '/\/var\/swap\/swapfile/d' /etc/fstab) &>/dev/null &&
(sudo bash -c 'echo /var/swap/swapfile none swap defaults,nofail 0 0 >> /etc/fstab') &>/dev/null &&
(sudo tee /etc/sysctl.d/99-swappiness.conf <<< "vm.swappiness = 180" 2>/dev/null || true) &>/dev/null &&

echo "[●] Step 8/8: Compiling lz4 acceleration drivers within system initramfs maps..." &&
(rpm-ostree initramfs --enable --arg=--add-drivers --arg=lz4 2>/dev/null || true) &>/dev/null

echo ""
echo "Setup Complete"
echo "Please reboot your system using the following command: systemctl reboot"
echo "After the system has rebooted, if you wish to test GPU overclocking, then run the following command in the terminal: systemctl start cyan-skillfish-governor-smu"
echo "CAUTION -> Overclocking the GPU can cause increased system heat and system instability"
