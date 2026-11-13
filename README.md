# archinstall

My own ready-to-install Arch Linux setup: **Hyprland** (Lua config) + **Noctalia** shell, kitty, starship, adw-gtk3-dark / Yaru icons.

> **Testing first?** See [EXPERIMENT.md](EXPERIMENT.md) — how to try this in a VM or throwaway user without risking your current apps, logins or Wi-Fi.

> **Calls echo or sound bad?** See [AUDIO.md](AUDIO.md): echo cancellation, the HD VOICE / HD SPEAKER devices, and how to tune them.

## Install on a fresh Arch system

1. Install base Arch (e.g. `archinstall`, minimal profile, NetworkManager, your user with sudo).
2. Log in as your user and run:

```bash
sudo pacman -S --needed git
git clone https://github.com/jasurlive/archinstall ~/archinstall
cd ~/archinstall && ./install.sh
```

3. Reboot and log in on tty1. Hyprland starts automatically.

Flags: `--no-packages` (only link configs), `--no-system` (skip services/pacman.conf).

## Layout

| Path | What it is | Installed to |
|---|---|---|
| `config/*` | app configs (hypr, kitty, noctalia, gtk, qt…) | symlinked into `~/.config/` |
| `config/pipewire/` | echo cancellation + voice tuning for calls ([AUDIO.md](AUDIO.md)) | symlinked into `~/.config/` |
| `home/.*` | `.bashrc`, `.bash_profile`, `.gtkrc-2.0` | symlinked into `~/` |
| `wallpapers/` | wallpapers | symlinked to `~/Pictures/Wallpapers` |
| `packages/pacman.txt` | official packages (+ anydesk-bin from Chaotic-AUR) | `pacman -S` |
| `packages/hardware-amd.txt` | AMD CPU/GPU drivers | only if an AMD GPU is detected |
| `vscode/` | pinned VSCode 1.91.1 + settings, keybindings, extensions | `vscode/install-vscode.sh` |
| `system/greetd/` | Noctalia greeter config (optional) | copy manually |

Configs are **symlinks**, so editing `~/.config/hypr/keybind.lua` edits the repo. Just `git commit` and push.
Existing files are moved to `~/.dotfiles-backup/<timestamp>/` before linking.

## Keeping the package list up to date

```bash
pacman -Qqen | grep -vxE 'chaotic-keyring|chaotic-mirrorlist|amd-ucode|vulkan-radeon|xf86-video-amdgpu|xf86-video-ati' > packages/pacman.txt
```
