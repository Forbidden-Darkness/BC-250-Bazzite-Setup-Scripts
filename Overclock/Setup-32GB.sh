#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  Setup-32GB (Bazzite) – NexGen3D v1.5 [Bazzite 44 Repaired]
# ────────────────────────────────────────────────────────────────
set -e

echo -e "\033[1;33m[●] Disabling legacy governor services...\033[0m"
sudo systemctl disable --now cyan-skillfish-governor 2>/dev/null || true
sudo systemctl disable --now cyan-skillfish-governor-tt 2>/dev/null || true
sudo systemctl disable --now oberon-governor 2>/dev/null || true

echo -e "\033[1;33m[●] Initializing COPR repository package maps...\033[0m"
sudo copr enable filippor/bazzite -y
sudo rpm-ostree cleanup -m 2>/dev/null || true
sudo rpm-ostree refresh-md || true

echo -e "\033[1;33m[●] Deploying Cyan Skillfish Governor Toolchain...\033[0m"
sudo rpm-ostree install cyan-skillfish-governor-smu lz4

echo -e "\033[1;33m[●] Adjusting atomic kernel parameters (Mitigations & ZSWAP)...\033[0m"
sudo rpm-ostree kargs --append-if-missing=mitigations=off || true
sudo rpm-ostree kargs --append-if-missing=zswap.enabled=1 || true
sudo rpm-ostree kargs --append-if-missing=zswap.max_pool_percent=25 || true
sudo rpm-ostree kargs --append-if-missing=zswap.compressor=lz4 || true
sudo rpm-ostree kargs --append-if-missing=systemd.zram=0 || true

echo -e "\033[1;33m[●] Provisioning BTRFS 32GB disk swapfile infrastructure...\033[0m"
sudo swapoff /var/swap/swapfile 2>/dev/null || true
sudo rm -f /var/swap/swapfile 2>/dev/null || true
sudo btrfs subvolume delete /var/swap 2>/dev/null || true
sudo btrfs subvolume create /var/swap

sudo semanage fcontext -a -t var_t /var/swap 2>/dev/null || true
sudo restorecon -R /var/swap 2>/dev/null || true

sudo btrfs filesystem mkswapfile --size 32G /var/swap/swapfile
sudo semanage fcontext -a -t swapfile_t /var/swap/swapfile 2>/dev/null || true
sudo restorecon /var/swap/swapfile 2>/dev/null || true

echo -e "\033[1;33m[●] Syncing persistent filesystem table mounts & vm properties...\033[0m"
sudo sed -i '\/var\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true
echo "/var/swap/swapfile none swap defaults,nofail 0 0" | sudo tee -a /etc/fstab >/dev/null
echo 'vm.swappiness = 180' | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null

echo -e "\033[1;33m[●] Generating runtime file system links...\033[0m"
sudo mkdir -p /etc/cyan-skillfish-governor
sudo ln -sfn /etc/cyan-skillfish-governor /etc/cyan-skillfish-governor-smu 2>/dev/null || true

echo -e "\033[1;33m[●] Building drivers into initramfs boot layers...\033[0m"
sudo rpm-ostree initramfs --enable --arg=--add-drivers --arg=lz4

echo -e "\033[1;32m"
echo "Setup Complete"
echo "Please reboot your system using the following command: systemctl reboot"
echo "After the system has rebooted, if you wish to test GPU overclocking, then run the following command in the terminal: systemctl start cyan-skillfish-governor-smu"
echo "CAUTION -> Overclocking the GPU can cause increased system heat and system instability"
echo -e "\033[0m"
