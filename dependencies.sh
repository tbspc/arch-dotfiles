#!/usr/bin/env bash
# Read-only overview. Some Impasto extras depend on CPU/GPU/camera or custom builds.
set -euo pipefail
repo=$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)
echo '=== CORE RESTORE PREREQUISITES ==='
for cmd in bash python3 rsync git pacman; do
  if command -v "$cmd" >/dev/null 2>&1; then printf 'OK          %s\n' "$cmd"; else printf 'NOT FOUND   %s\n' "$cmd"; fi
done
echo '=== DESKTOP RUNTIME ==='
for cmd in Hyprland hyprctl quickshell fish starship kitty awww dconf codium yay flatpak; do
  if command -v "$cmd" >/dev/null 2>&1; then printf 'OK          %s\n' "$cmd"; else printf 'NOT FOUND   %s\n' "$cmd"; fi
done
echo '=== OPTIONAL CAMERA/PYTHON FEATURES ==='
python3 - <<'PY'
import importlib.util
for name in ('mediapipe', 'cv2', 'PySide6'):
    try:
        status = 'OK' if importlib.util.find_spec(name) else 'NOT FOUND'
    except (ModuleNotFoundError, ValueError):
        status = 'NOT FOUND'
    print(f'{status:11} python module {name}')
PY
echo '=== SNAPSHOT PACKAGE LISTS ==='
for f in pacman.txt aur-local.txt flatpak.txt vscodium-extensions.txt; do
  if [[ -s "$repo/packages/$f" ]]; then
    printf '%-26s %s entries\n' "$f" "$(wc -l < "$repo/packages/$f")"
  else
    printf '%-26s %s\n' "$f" '(not captured or empty)'
  fi
done
echo '=== NEW LAPTOP CHECKS (MANUAL) ==='
echo 'Arch already booting; GPU drivers; displays; audio; sudo; network; correct Hyprland version.'
echo 'Impasto-specific optional plugins, camera virtual device, PipeWire and Python dependencies may need separate setup.'
echo 'Never migrate /boot, /etc/fstab, bootloader, Plymouth or microcode from original laptop.'
