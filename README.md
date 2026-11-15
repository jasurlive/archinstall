# archinstall

My own ready-to-install Arch Linux setup: **Hyprland** (Lua config) + **[hyprminimal](https://github.com/jasurlive/hyprminimal)** shell (bar, launcher, notifications, OSD, lock screen, greeter), kitty, starship, adw-gtk3-dark / Yaru-blue-dark icons / Bibata-Modern-Classic cursor, Tokyo Night Moon colours everywhere.

**No AUR builds:** everything comes from the official repos or as prebuilt binaries from Chaotic-AUR (`anydesk-bin`, `bibata-cursor-theme`, `yaru-icon-theme`, `humanity-icon-theme`, `papirus-folders`, `ttf-ms-fonts`, `ttf-symbola`). No AUR helper is needed.

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

3. Reboot. greetd logs you in and Hyprland opens on the hyprminimal lock screen: unlock with your password. After logging out you get the hyprminimal greeter (pick a user with Up/Down).

`install.sh` clones hyprminimal into `~/www/hyprminimal` (the Hyprland config expects it there) and installs its packages from `packages.txt`.

Flags: `--no-packages` (only link configs), `--no-system` (skip services/greetd), `--no-autologin` (show the greeter at boot instead of the lock screen).

## Layout

| Path | What it is | Installed to |
|---|---|---|
| `config/*` | app configs (hypr, kitty, gtk, qt, starship…) | symlinked into `~/.config/` |
| `config/pipewire/` | echo cancellation + voice tuning for calls ([AUDIO.md](AUDIO.md)), 7.1 virtual surround (HeSuVi `atmos.wav`) | symlinked into `~/.config/` |
| `config/{nwg-displays,xfce4,gh,Pinta,gedit}`, `kdeglobals`, `pavucontrol.ini` | monitor profiles, Thunar, gh, Pinta, gedit, KDE/Qt colours, pavucontrol | symlinked into `~/.config/` |
| `dconf/user.ini` | GTK/GNOME app settings (`dconf dump /`) | loaded with `dconf load /` |
| `home/.*` | `.bashrc`, `.bash_profile`, `.gtkrc-2.0` | symlinked into `~/` |
| `wallpapers/` | wallpapers | symlinked to `~/Pictures/Wallpapers` |
| `packages/pacman.txt` | official packages (+ a few prebuilt Chaotic-AUR ones) | `pacman -S` |
| `packages/hardware-amd.txt` | AMD CPU/GPU drivers | only if an AMD GPU is detected |
| `vscode/` | pinned VSCode 1.91.1 + settings, keybindings, extensions | `vscode/install-vscode.sh` |
| `system/greetd/` | greetd config: autologin into the hyprminimal lock screen, hyprminimal greeter after logout | copied to `/etc/greetd/` (`@USER@` = you), greeter installed with `hyprminimal-greeter install`, greetd enabled |
| `~/www/hyprminimal` | the shell, from [jasurlive/hyprminimal](https://github.com/jasurlive/hyprminimal) | `git clone` |

Configs are **symlinks**, so editing `~/.config/hypr/keybind.lua` edits the repo. Just `git commit` and push.
Existing files are moved to `~/.dotfiles-backup/<timestamp>/` before linking.

## Keeping the package list up to date

```bash
pacman -Qqen | grep -vxE 'chaotic-keyring|chaotic-mirrorlist|yay|amd-ucode|vulkan-radeon|xf86-video-amdgpu|xf86-video-ati' > packages/pacman.txt
```

## Keeping dconf settings up to date

```bash
dconf dump / > dconf/user.ini
```

## Not in this repo (back these up separately)

Secrets and personal data: `~/.ssh`, GPG keys, `~/.local/share/keyrings`, `gh` login (`config/gh/hosts.yml` is git-ignored, run `gh auth login`), browser profiles, Wi-Fi passwords, and your files.
