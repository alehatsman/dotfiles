#!/usr/bin/env bash
# Arch Linux installer for ThinkPad X1 Carbon Gen 13 Aura Edition
# Run from the Arch live ISO after connecting to the internet via iwctl
set -euo pipefail

# ── Configuration — edit before running ───────────────────────────────────────
DISK="${DISK:-/dev/nvme0n1}"
INSTALL_HOSTNAME="${INSTALL_HOSTNAME:-thinkpad}"
USERNAME="${USERNAME:-alehatsman}"
TIMEZONE="${TIMEZONE:-Europe/Amsterdam}"
LOCALE="${LOCALE:-en_US.UTF-8}"
DOTFILES_REPO="https://github.com/alehatsman/dotfiles"

# ── Helpers ───────────────────────────────────────────────────────────────────
info() { printf '\n\e[1;34m==> %s\e[0m\n' "$*"; }
die()  { printf '\e[1;31mERROR: %s\e[0m\n' "$*" >&2; exit 1; }

# ── Pre-flight ────────────────────────────────────────────────────────────────
[[ -d /sys/firmware/efi/efivars ]] || die "Not in UEFI mode — check BIOS: Secure Boot off, UEFI only"
ping -c 1 -W 3 archlinux.org >/dev/null 2>&1 || die "No internet. Connect first with: iwctl"

info "Install configuration"
echo "  Disk:     $DISK"
echo "  Hostname: $INSTALL_HOSTNAME"
echo "  Username: $USERNAME"
echo "  Timezone: $TIMEZONE"
echo ""
lsblk "$DISK"
echo ""
read -rp "Proceed? THIS WILL WIPE $DISK [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || exit 0

# ── Unmount any previous install ─────────────────────────────────────────────
info "Unmounting any existing mounts..."
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true

# ── Partitions ────────────────────────────────────────────────────────────────
info "Partitioning $DISK..."
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G  -t 1:ef00 -c 1:EFI  "$DISK"
sgdisk -n 2:0:+8G  -t 2:8200 -c 2:swap "$DISK"
sgdisk -n 3:0:0    -t 3:8300 -c 3:root "$DISK"
partprobe "$DISK"
udevadm settle

[[ "$DISK" == *nvme* ]] && SEP="p" || SEP=""
EFI="${DISK}${SEP}1"
SWAP="${DISK}${SEP}2"
ROOT="${DISK}${SEP}3"

# ── Format ────────────────────────────────────────────────────────────────────
info "Formatting partitions..."
mkfs.fat -F32 "$EFI"
mkswap "$SWAP"
mkfs.btrfs -f "$ROOT"

# ── Btrfs subvolumes ──────────────────────────────────────────────────────────
info "Creating btrfs subvolumes..."
mount "$ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt

# ── Mount ─────────────────────────────────────────────────────────────────────
info "Mounting subvolumes..."
BTRFS_OPTS="compress=zstd:3,noatime,space_cache=v2"
mount -o "${BTRFS_OPTS},subvol=@"          "$ROOT" /mnt
mkdir -p /mnt/{home,.snapshots,var/log,boot}
mount -o "${BTRFS_OPTS},subvol=@home"      "$ROOT" /mnt/home
mount -o "${BTRFS_OPTS},subvol=@snapshots" "$ROOT" /mnt/.snapshots
mount -o "${BTRFS_OPTS},subvol=@var_log"   "$ROOT" /mnt/var/log
mount "$EFI" /mnt/boot
swapon "$SWAP"

ROOT_UUID=$(blkid -s UUID -o value "$ROOT")

# ── Mirrors ───────────────────────────────────────────────────────────────────
info "Ranking mirrors..."
reflector --country Netherlands,Germany --protocol https --age 12 --sort rate --latest 10 --save /etc/pacman.d/mirrorlist

# ── Base system ───────────────────────────────────────────────────────────────
info "Installing base system..."
pacstrap -K /mnt \
  base base-devel linux linux-firmware \
  intel-ucode \
  btrfs-progs \
  networkmanager \
  git curl wget \
  sudo vim \
  man-db man-pages

info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ── Chroot setup ──────────────────────────────────────────────────────────────
info "Writing chroot setup script..."
cat > /mnt/root/arch-setup.sh << SCRIPT
#!/bin/bash
set -euo pipefail

INSTALL_HOSTNAME="$INSTALL_HOSTNAME"
USERNAME="$USERNAME"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
ROOT_UUID="$ROOT_UUID"

# Timezone
ln -sf /usr/share/zoneinfo/\$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
sed -i "s/^#\${LOCALE}/\${LOCALE}/" /etc/locale.gen
locale-gen
echo "LANG=\${LOCALE}" > /etc/locale.conf

# Hostname
echo "\$INSTALL_HOSTNAME" > /etc/hostname
{
  echo "127.0.0.1 localhost"
  echo "::1       localhost"
  echo "127.0.1.1 \${INSTALL_HOSTNAME}.localdomain \${INSTALL_HOSTNAME}"
} > /etc/hosts

# mkinitcpio — add btrfs to MODULES
sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P

# NetworkManager
systemctl enable NetworkManager

# Root password (temporary — change after first boot with: passwd)
echo "root:changeme" | chpasswd

# User
useradd -m -G wheel,audio,video,storage -s /bin/bash "\$USERNAME"
echo "\$USERNAME:changeme" | chpasswd

# Sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Bootloader
bootctl install
mkdir -p /boot/loader/entries
cat > /boot/loader/loader.conf << EOF
default arch.conf
timeout 3
editor no
EOF
cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=\${ROOT_UUID} rootflags=subvol=@ rw quiet
EOF

echo ""
echo "Chroot setup complete."
SCRIPT

chmod +x /mnt/root/arch-setup.sh
arch-chroot /mnt /root/arch-setup.sh
rm /mnt/root/arch-setup.sh

# ── Done ──────────────────────────────────────────────────────────────────────
info "Installation complete!"
echo ""
echo "  1. umount -R /mnt && reboot  (remove the USB)"
echo "  2. Login as $USERNAME  (password: changeme — change it!)"
echo "  3. curl -sL ${DOTFILES_REPO}/raw/main/platforms/arch/bootstrap.sh | bash"
echo ""
