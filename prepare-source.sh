#!/usr/bin/env bash
# Run on CURRENT laptop. Copies selected portable configuration into this repository.
set -euo pipefail
if [[ "${EUID}" -eq 0 ]]; then echo 'Do not run as root.' >&2; exit 1; fi
repo=$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)
[[ -d "$repo/home" ]] || { echo "Missing $repo/home — this tool must live in your existing ~/arch-dotfiles." >&2; exit 1; }
for cmd in rsync pacman python3; do command -v "$cmd" >/dev/null || { echo "Missing prerequisite: $cmd" >&2; exit 1; }; done
mkdir -p "$repo/metadata" "$repo/packages" "$repo/home/.config" "$repo/home/.local/share" "$repo/home/.local/bin"
printf '%s\n' "$HOME" > "$repo/metadata/source-home.txt"
printf '%s\n' "$(uname -m)" > "$repo/metadata/source-architecture.txt"
# Copy known desktop/shell configs but not app caches, browser profiles, or login state.
configs=(hypr quickshell sane-settings fish kitty fastfetch btop cava nvim mpv yazi imv gpick gtk-3.0 gtk-4.0 qt6ct kdeglobals qalculate SpeedCrunch spicetify pipewire systemd environment.d nautilus)
for name in "${configs[@]}"; do
  if [[ -d "$HOME/.config/$name" ]]; then
    mkdir -p "$repo/home/.config/$name"
    rsync -a --exclude='backups/' --exclude='*.log' --exclude='*.log.*' --exclude='__pycache__/' --exclude='fish_variables' \
      "$HOME/.config/$name/" "$repo/home/.config/$name/"
  fi
done
for name in starship.toml mimeapps.list user-dirs.dirs user-dirs.locale brave-flags.conf; do
  [[ -f "$HOME/.config/$name" ]] && cp -a "$HOME/.config/$name" "$repo/home/.config/" || true
done
for name in .icons .gtk-3.0 .bashrc .bash_profile .profile .zshrc; do
  [[ -e "$HOME/$name" ]] && cp -a "$HOME/$name" "$repo/home/" || true
done
# All Impasto profiles/models and assets are saved locally; the camera sample photo is excluded from export later.
if [[ -d "$HOME/.local/share/impasto" ]]; then
  mkdir -p "$repo/home/.local/share/impasto"
  rsync -a --exclude='*.log' "$HOME/.local/share/impasto/" "$repo/home/.local/share/impasto/"
fi
for name in fonts icons themes wallpapers applications; do
  if [[ -d "$HOME/.local/share/$name" ]]; then
    mkdir -p "$repo/home/.local/share/$name"
    rsync -a "$HOME/.local/share/$name/" "$repo/home/.local/share/$name/"
  fi
done
for name in impasto sane-settings; do
  [[ -f "$HOME/.local/bin/$name" ]] && cp -a "$HOME/.local/bin/$name" "$repo/home/.local/bin/" || true
done
for rel in deckcraft/ui.json deckcraft/prefs.json gridcraft/ui.json gridcraft/prefs.json pdfcraft/app.ron wordcraft/ui.json wordcraft/fonts/times.ttf; do
  if [[ -f "$HOME/.config/$rel" ]]; then
    mkdir -p "$repo/home/.config/$(dirname "$rel")"
    cp -a "$HOME/.config/$rel" "$repo/home/.config/$rel"
  fi
done
for rel in settings.json keybindings.json tasks.json; do
  if [[ -f "$HOME/.config/VSCodium/User/$rel" ]]; then
    mkdir -p "$repo/home/.config/VSCodium/User"
    cp -a "$HOME/.config/VSCodium/User/$rel" "$repo/home/.config/VSCodium/User/$rel"
  fi
done
if [[ -d "$HOME/.config/VSCodium/User/snippets" ]]; then
  mkdir -p "$repo/home/.config/VSCodium/User/snippets"
  rsync -a "$HOME/.config/VSCodium/User/snippets/" "$repo/home/.config/VSCodium/User/snippets/"
fi
pacman -Qqen > "$repo/packages/pacman.txt"
pacman -Qqem > "$repo/packages/aur-local.txt"
if command -v flatpak >/dev/null; then
  flatpak list --app --columns=application > "$repo/packages/flatpak.txt"
fi
if command -v codium >/dev/null; then codium --list-extensions > "$repo/packages/vscodium-extensions.txt" || true; fi
if command -v dconf >/dev/null; then dconf dump /org/gnome/desktop/interface/ > "$repo/packages/gtk-interface.dconf"; fi
if command -v fish >/dev/null; then
  fish -c 'abbr --show' > "$repo/packages/fish-abbreviations.fish" || true
fi
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null | awk '{print $1}' > "$repo/packages/enabled-user-services.txt" || true
chmod -R go-rwx "$repo/metadata" "$repo/packages"
echo "Snapshot refreshed at $repo"
echo 'WARNING: Review files in home/ and packages/ before publishing. No Git upload was performed.'
