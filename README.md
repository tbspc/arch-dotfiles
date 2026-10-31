# Arch + Hyprland / Quickshell / Impasto dotfiles installer

Built for an existing `~/arch-dotfiles/home/` snapshot. **This package contains installer scripts, not your actual dotfiles or the 1.5 GB of wallpapers/fonts.** Place these files into the root of your snapshot, then run the commands below on the correct laptop.

## What is preserved

- `home/.config/hypr/` (Hyprland Lua config), `home/.config/quickshell/` (QML, shaders, layouts, settings), `home/.config/sane-settings/`
- `home/.local/share/impasto/` (profiles, palette, camera models), `home/.local/bin/impasto`
- Fish, Starship, Kitty and other configs already captured
- `home/.local/share/wallpapers/`, `fonts/`, `icons/`, `themes/`, `applications/`; `home/.icons`
- Package manifests and optional dconf, VSCodium extension and Fish abbreviation exports

This does **not** clone your full OS. It never writes to `/etc`, `/boot`, EFI, SDDM, Plymouth, partition tables or bootloader, and does not enable systemd services. Impasto's own upstream installer may configure some of these: **do not run it blindly** on a machine with a custom boot setup.

## Prerequisites

**Source laptop** (already working): Arch Linux, normal user (not root), Bash, Python 3, `rsync`, `pacman`, enough free disk space for a second 1.5 GB asset copy. Fish is optional for producing the abbreviations export. Install prerequisites if missing:

```bash
sudo pacman -S --needed bash python rsync git
```

**Destination laptop**: **Arch Linux already installed and booting**, matching CPU architecture (usually x86_64); normal account with `sudo`, networking; working GPU driver, audio, display, and correct monitor settings. For core restore: `bash`, `python`, `rsync` (for transferring files), and ~2 GB of free space or more. For desktop functionality: `hyprland` version **0.56+**, `quickshell`, `fish`, `starship`, `kitty`, fonts/icons, `yay` (optional for AUR), `flatpak` (optional), and any extra packages from your saved manifests. `dconf` and `codium` are optional for settings/extensions. Your specific GPU, camera, and monitor may need separately chosen packages/settings.

The upstream Impasto project lists additional features requiring `awww`, Hyprland plugins (`hyprglass`, `hypr-dynamic-cursors`), MediaPipe, `v4l2loopback`, and more. These depend on machine and version; **the scripts do not assume they work**. See https://github.com/andreumassanet/impasto.

## On the ORIGINAL laptop (Fish shell is fine)

After unpacking this archive into `~/arch-dotfiles` (so `~/arch-dotfiles/install.sh` exists):

```fish
cd ~/arch-dotfiles
bash ./prepare-source.sh
bash ./check-repo.sh
bash ./dependencies.sh
bash ./verify.sh --source
bash ./export-safe.sh
```

`prepare-source.sh` refreshes selected settings, Impasto data and package manifests, and writes `metadata/source-home.txt` (e.g. `/home/tbs`). **It does not delete or replace your running desktop config.** It also copies large wallpapers and fonts; most are already present.

`export-safe.sh` only previews a new transfer directory. Then run:

```fish
bash ./export-safe.sh --apply
```

**Security warning:** The export omits known logs, Quickshell backups, local control keys, and a potentially personal camera sample photo. This is a *best-effort* filter, not a guarantee that other secrets aren't present. Manually audit the exported directory before publishing it, even to a private Git repository. Don't publish API tokens, private keys, browser profiles, password databases, or personal artwork without permission. An external USB SSD / `rsync` avoids placing your 1.5 GB of assets on GitHub. For Git hosting, review Git LFS quotas/license permissions and carefully review each file before `git add`/push.

## Transfer to the other laptop

**USB drive** (safe, no cloud, recommended for ~1.5 GB of wallpapers/fonts): copy the newly created `~/arch-dotfiles-transfer-.../` directory onto a USB SSD, then copy it onto the second laptop as `~/arch-dotfiles/`. Keep file permissions with `rsync -a` if possible.

**Network** example from source laptop, after replacing `OTHER_USER`, `OTHER_HOST`, and `EXPORT_DIR`:

```bash
rsync -a --info=progress2 "$HOME/EXPORT_DIR/" OTHER_USER@OTHER_HOST:~/arch-dotfiles/
```

(The remote target needs SSH enabled and you should validate the hostname. The command is only an example.)

## On the SECOND laptop (Fish or Bash)

Install bootstrap tools:

```bash
sudo pacman -Syu --needed bash python rsync git
```

From the transferred folder:

```bash
cd ~/arch-dotfiles
./dependencies.sh                     # prints installed/missing prerequisites
./install-packages.sh                 # previews official package list and machine-specific exclusions
./install-packages.sh --apply         # OPTIONAL: restores compatible official repo packages
./install-packages.sh --aur           # previews AUR/local candidates
./install-packages.sh --apply --aur   # OPTIONAL: requires yay, may require manual corrections
./install-packages.sh --apply --flatpak  # OPTIONAL: needs flatpak + Flathub
./install.sh                          # previews files, changes nothing
./install.sh --apply                  # requests typing RESTORE; backs up changed files
./verify.sh                           # checks required Impasto files and source/target equality
```

The installer copies only `home/` under your user home. Before replacing a file it saves a copy to `~/.local/state/arch-dotfiles-backups/<timestamp>/`. No files are deleted simply because they are absent from the snapshot. It rewrites the **old home prefix** (e.g. `/home/tbs`) to the new `$HOME` in common small UTF-8 text configs including Quickshell QML and `.desktop` launchers; binary files are copied unchanged. **Review the warnings and adjust monitor names, camera devices, and machine-specific settings manually.**

You can also inspect packages manually:

```bash
cat packages/pacman.txt
cat packages/aur-local.txt
cat packages/enabled-user-services.txt
```

The package step automatically excludes common bootloader, kernel, microcode, GPU driver and Plymouth entries, but cannot know every hardware-specific package. Review the list. `--aur` candidates may include manually installed packages not present on the AUR.

## Optional manual extras

- Fish abbreviations saved to `packages/fish-abbreviations.fish`: review first, then manually import into Fish if wanted. No scripts automatically execute arbitrary saved shell commands.
- GTK interface dconf dump is in `packages/gtk-interface.dconf`: review before running `dconf load /org/gnome/desktop/interface/ < packages/gtk-interface.dconf` under your normal graphical user session.
- VSCodium extensions in `packages/vscodium-extensions.txt`: review then install with `codium --install-extension EXTENSION_ID` per extension.
- Systemd user service names are exported but not automatically enabled. Check that service packages are installed before enabling them.
- Your Fish shell can be made default with `chsh -s /usr/bin/fish` **only after** Fish is installed and listed in `/etc/shells`.

## Verification and known limits

`./verify.sh --source` checks that the captured Hyprland, Quickshell, Impasto, Sane Settings and launcher files are present. `./verify.sh` compares all captured files with the target after applying home path conversion. A passing comparison means bytes match, **not** that Impasto's optional GPU effects, webcam processing, plugins, display settings, audio or services have been verified at runtime. A second-machine runtime test is still needed.

In particular, examine `home/.config/quickshell/theme/Palettes.qml`, any desktop launcher with hardcoded paths, and `home/.config/hypr/modules/monitors.lua` before running Hyprland on another laptop.

## Rollback

If a target file was replaced, the original is saved at the same relative path under the timestamped backup directory. To undo a change, close the affected application, locate the backup and copy that file back. This installer does not offer an automatic bulk rollback because doing so could overwrite subsequent changes.
