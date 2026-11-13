#!/usr/bin/env bash
# Arch + Hyprland + Noctalia setup.
# Run as your normal user on a fresh Arch install (after archinstall / base setup):
#   git clone https://github.com/jasurlive/archinstall ~/archinstall && cd ~/archinstall && ./install.sh
#
# Flags:
#   --no-packages   skip package installation (only link configs)
#   --no-system     skip system tweaks (pacman.conf, services, greetd)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DO_PACKAGES=1
DO_SYSTEM=1
for arg in "$@"; do
  case $arg in
    --no-packages) DO_PACKAGES=0 ;;
    --no-system)   DO_SYSTEM=0 ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

info() { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m==>\e[0m %s\n' "$*"; }

[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root."; exit 1; }
command -v pacman >/dev/null || { echo "This script is for Arch Linux."; exit 1; }
sudo -v

# Read a package list, ignoring comments and blank lines
pkglist() { grep -vE '^\s*(#|$)' "$1"; }

# ---------------------------------------------------------------- repos
setup_repos() {
  info "Enabling multilib"
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  fi

  info "Enabling Chaotic-AUR (prebuilt binary for anydesk-bin; everything else is official)"
  if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
    sudo pacman-key --init
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm \
      'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
      'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
  fi
  sudo pacman -Syu --noconfirm
}

# ---------------------------------------------------------------- packages
install_packages() {
  info "Installing packages (official + Chaotic-AUR binaries, via pacman)"
  # shellcheck disable=SC2046
  sudo pacman -S --needed --noconfirm $(pkglist "$DOTFILES/packages/pacman.txt")

  if lspci | grep -Ei 'vga|3d|display' | grep -qiE 'amd|ati|radeon'; then
    info "AMD GPU detected — installing AMD drivers"
    # shellcheck disable=SC2046
    sudo pacman -S --needed --noconfirm $(pkglist "$DOTFILES/packages/hardware-amd.txt")
  else
    warn "No AMD GPU detected — skipping packages/hardware-amd.txt (install your GPU drivers manually)"
  fi
}

# ---------------------------------------------------------------- dotfiles
# Symlink $1 (in repo) -> $2 (in $HOME), backing up whatever was there.
link() {
  local src=$1 dst=$2
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then return; fi
  if [[ -e $dst || -L $dst ]]; then
    mkdir -p "$BACKUP/$(dirname "${dst#"$HOME"/}")"
    mv "$dst" "$BACKUP/${dst#"$HOME"/}"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  linked ${dst/#$HOME/~}"
}

link_dotfiles() {
  info "Linking configs into ~/.config"
  for item in "$DOTFILES"/config/* ; do
    link "$item" "$HOME/.config/$(basename "$item")"
  done

  info "Linking home dotfiles"
  for item in "$DOTFILES"/home/.[!.]* ; do
    [[ -e $item ]] && link "$item" "$HOME/$(basename "$item")"
  done

  info "Linking wallpapers"
  link "$DOTFILES/wallpapers" "$HOME/Pictures/Wallpapers"

  chmod +x "$DOTFILES"/config/hypr/Scripts/*.sh 2>/dev/null || true
  [[ -d $BACKUP ]] && warn "Old files were backed up to $BACKUP"
}

# ---------------------------------------------------------------- system
setup_system() {
  info "Enabling services"
  sudo systemctl enable NetworkManager.service power-profiles-daemon.service \
    cups.socket fstrim.timer systemd-timesyncd.service
  systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service || true

  # greetd config is kept for reference; login currently happens on tty1 via
  # ~/.bash_profile (exec start-hyprland). To use the Noctalia greeter instead:
  #   sudo cp system/greetd/config.toml /etc/greetd/ && sudo systemctl enable greetd

  info "Creating user dirs"
  xdg-user-dirs-update || true

  if [[ $SHELL != */bash ]]; then
    warn "Your login shell is $SHELL; this setup expects bash (it auto-starts Hyprland on tty1)."
  fi
}

# ---------------------------------------------------------------- run
if (( DO_PACKAGES )); then setup_repos; install_packages; fi
link_dotfiles
if (( DO_PACKAGES )); then
  info "Installing pinned VSCode"
  "$DOTFILES/vscode/install-vscode.sh"
fi
if (( DO_SYSTEM )); then setup_system; fi

info "Done! Log out and log in on tty1 to start Hyprland."
