#!/usr/bin/env bash
# Package restore is always optional. Does not touch bootloader/kernel/system configuration.
set -euo pipefail
if (( EUID == 0 )); then echo 'Run as your normal user, not root.' >&2; exit 1; fi
repo=$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)
apply=0; aur=0; flatpak_apps=0
usage(){ echo 'Usage: ./install-packages.sh [--apply] [--aur] [--flatpak]'; echo 'Default: dry-run. --aur and --flatpak opt in to those package sources.'; }
for arg in "$@"; do
  case "$arg" in
    --apply) apply=1;;
    --aur) aur=1;;
    --flatpak) flatpak_apps=1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option $arg" >&2; usage; exit 1;;
  esac
done
command -v pacman >/dev/null || { echo 'Requires Arch Linux/pacman' >&2; exit 1; }
[[ -f "$repo/packages/pacman.txt" ]] || { echo 'Missing packages/pacman.txt' >&2; exit 1; }
# Do not auto-copy machine-specific packages such as bootloaders, kernels,
# video drivers or boot-related tools. New laptop should already boot Arch.
is_machine_specific() {
  case "$1" in
    linux|linux-headers|linux-lts|linux-lts-headers|linux-zen|linux-zen-headers|linux-hardened|linux-hardened-headers|linux-rt|linux-rt-lts|\
    amd-ucode|intel-ucode|refind|grub|efibootmgr|plymouth|mkinitcpio|dracut|sbctl|shim|systemd-ukify|\
    nvidia|nvidia-*|lib32-nvidia-utils|xf86-video-*|virtualbox-host-*|v4l2loopback-*|broadcom-wl*)
      return 0;;
  esac
  return 1
}
mapfile -t candidates < <(grep -vE '^[[:space:]]*(#|$)' "$repo/packages/pacman.txt" | sort -u)
packages=(); skipped=()
for pkg in "${candidates[@]}"; do
  if is_machine_specific "$pkg"; then skipped+=("$pkg"); else packages+=("$pkg"); fi
done
printf 'Official packages proposed: %d\n' "${#packages[@]}"
printf 'Machine-specific packages excluded: %s\n' "${skipped[*]:-(none)}"
echo 'Review packages/pacman.txt and your new laptop hardware before applying.'
if (( aur )); then
  mapfile -t foreign < <(grep -vE '^[[:space:]]*(#|$)' "$repo/packages/aur-local.txt" 2>/dev/null | sort -u)
  echo "Foreign/AUR candidates (${#foreign[@]}): ${foreign[*]:-(none)}"
  echo 'WARNING: foreign list can contain LOCAL, non-AUR packages. Review each one.'
fi
if (( flatpak_apps )) && [[ -f "$repo/packages/flatpak.txt" ]]; then cat "$repo/packages/flatpak.txt"; fi
if (( ! apply )); then echo 'DRY RUN: no packages installed. Pass --apply to proceed.'; exit 0; fi
read -r -p 'Type PACKAGES to permit package-manager changes: ' reply
[[ "$reply" == 'PACKAGES' ]] || { echo 'Cancelled.'; exit 0; }
# Refresh databases and system together to avoid partial upgrades.
sudo pacman -Syu
if ((${#packages[@]})); then
  # Only install packages actually available in the official repositories.
  declare -A available_map=()
  while IFS= read -r pkg; do available_map["$pkg"]=1; done < <(pacman -Slq)
  official=(); unknown=()
  for pkg in "${packages[@]}"; do
    if [[ -n "${available_map[$pkg]:-}" ]]; then official+=("$pkg"); else unknown+=("$pkg"); fi
  done
  printf 'Not available in enabled official repositories: %s\n' "${unknown[*]:-(none)}"
  if ((${#official[@]})); then sudo pacman -S --needed -- "${official[@]}"; fi
fi
if (( aur )); then
  command -v yay >/dev/null || { echo 'yay required for optional foreign packages. Install/review it separately.'; exit 1; }
  echo 'Review this foreign/AUR list; not all entries are installable from AUR:'
  printf '  %s\n' "${foreign[@]}"
  read -r -p 'Type AUR to attempt all listed foreign packages using yay: ' r
  if [[ "$r" == 'AUR' ]] && ((${#foreign[@]})); then yay -S --needed -- "${foreign[@]}"; fi
fi
if (( flatpak_apps )); then
  command -v flatpak >/dev/null || { echo 'flatpak required; skipping.'; exit 1; }
  if [[ -f "$repo/packages/flatpak.txt" ]]; then
    mapfile -t apps < <(grep -vE '^[[:space:]]*(#|$)' "$repo/packages/flatpak.txt" | sort -u)
    if ((${#apps[@]})); then
      echo 'Requires Flathub (or another configured remote) on the target.'
      flatpak install --user flathub "${apps[@]}"
    fi
  fi
fi
