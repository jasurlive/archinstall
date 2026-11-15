# EXPERIMENT.md — testing this repo safely

How to test `install.sh` **without** touching the apps, configs, logins, Wi-Fi
passwords or keyring on your current daily Arch machine.

## ⚠️ The one rule

**Do NOT run `./install.sh` (the full run) on your daily machine.**

The full script will, on the machine it runs on:
- enable repos and run `pacman -Syu` (system-wide upgrade),
- install ~160 packages,
- **symlink over** `~/.config/hypr`, `~/.config/kitty`, `~/.config/Code/User/…`,
  etc. (originals are moved to `~/.dotfiles-backup/<timestamp>/`, but your live
  setup is replaced),
- `sudo rm -rf /opt/vscode` and reinstall VSCode,
- enable systemd services.

It never *deletes* your apps or passwords, but it rewrites your desktop config
and system state. Test it somewhere disposable instead. Pick one option below.

---

## Option A — Virtual machine (recommended, zero risk)

Nothing on your real machine is touched. This is the only way to test the
*full* script including packages, repos, VSCode and services.

```bash
sudo pacman -S --needed qemu-full virt-manager   # one-time, on your real machine
# Download the Arch ISO: https://archlinux.org/download/
```

1. In **virt-manager**: New VM → the Arch ISO → give it ~8 GB RAM, 30 GB disk,
   and enable **3D acceleration / Virtio-GPU** (Hyprland needs GPU; in a VM you
   may also need `WLR_RENDERER_ALLOW_SOFTWARE=1`).
2. Install base Arch with `archinstall` (minimal profile, NetworkManager, make a
   sudo user).
3. Inside the VM:
   ```bash
   sudo pacman -S --needed git
   git clone https://github.com/jasurlive/archinstall ~/archinstall
   cd ~/archinstall && ./install.sh
   reboot          # hyprminimal lock screen → unlock → Hyprland + hyprminimal
   ```
4. Break it, wipe the VM, repeat. Your real machine never sees any of it.

---

## Option B — Throwaway user on THIS machine (config-only, no packages)

Tests only the **config linking** (Hyprland/kitty/hyprminimal/VSCode settings),
not package install or services. Safe because a second user has a separate
`$HOME`; your own `~`, keyring, browsers and Wi-Fi are untouched.

```bash
sudo useradd -m -G wheel testrice
sudo passwd testrice
sudo machinectl shell testrice@   # or: su - testrice

# as testrice:
git clone https://github.com/jasurlive/archinstall ~/archinstall
cd ~/archinstall
./install.sh --no-packages --no-system   # links configs into testrice's home only
```

Then from a TTY (Ctrl+Alt+F3), log in as `testrice` and `start-hyprland` to see
the rice. When done:

```bash
sudo userdel -r testrice          # removes the test user and its home entirely
```

This cannot affect your login because everything lands in `/home/testrice`.

---

## What holds your logins & passwords — never let a test touch these

A test is safe as long as it does **not** write to, symlink over, or delete any
of these (none are in this repo, so `install.sh` already leaves them alone — but
know where they live):

| What | Location |
|---|---|
| Saved app passwords / secrets (keyring) | `~/.local/share/keyrings/` |
| Wi-Fi passwords | `/etc/NetworkManager/system-connections/` (root-only) |
| Firefox logins/cookies | `~/.mozilla/` |
| Chromium/Chrome logins | `~/.config/chromium/` |
| SSH keys | `~/.ssh/` |
| GitHub CLI auth | `~/.config/gh/` |
| AnyDesk identity | `~/.anydesk/` |
| Telegram session | `~/.local/share/TelegramDesktop/` |

**Back them up before any experiment** (copy to an external drive or a tarball):

```bash
tar czf ~/logins-backup-$(date +%F).tar.gz \
  ~/.local/share/keyrings ~/.ssh ~/.config/gh ~/.anydesk \
  ~/.mozilla ~/.config/chromium ~/.local/share/TelegramDesktop 2>/dev/null
sudo tar czf /root/wifi-backup.tar.gz /etc/NetworkManager/system-connections
```

Note: the keyring is encrypted with your **login password**, so it only
unlocks on a machine where you log in with the same password/user.

---

## If you only want to preview the config changes on your real machine

Because configs are symlinks, the rice edits are already live on your machine
(that's how we built the repo). To preview a *single* changed file without
committing, just open it. To undo any experiment on your own `~/.config`,
restore from the backup the installer made:

```bash
ls ~/.dotfiles-backup/        # timestamped folders of whatever was replaced
```

---

## Quick decision guide

| You want to… | Use |
|---|---|
| Test the **whole thing** (packages, repos, services, VSCode) | **Option A (VM)** |
| Just see the **rice/configs** without risking your system | **Option B (test user)** |
| Keep your current desktop exactly as-is | Don't run the full `install.sh` here at all |
