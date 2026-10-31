#!/usr/bin/env bash
# Prepare a fresh shareable copy, with known private/stateful files omitted.
set -euo pipefail
if (( EUID == 0 )); then echo 'Do not run as root.' >&2; exit 1; fi
repo=$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)
command -v rsync >/dev/null || { echo 'Install rsync first: sudo pacman -S rsync' >&2; exit 1; }
apply=0
out="${HOME}/arch-dotfiles-transfer-$(date -u +%Y%m%dT%H%M%SZ)"
for arg in "$@"; do
  case "$arg" in
    --apply) apply=1;;
    --help|-h) echo 'Usage: ./export-safe.sh [--apply] [--output=/absolute/path]'; exit 0;;
    --output=*) out="${arg#--output=}";;
    *) echo "Unknown argument: $arg" >&2; exit 1;;
  esac
done
[[ "$out" == /* ]] || { echo 'Output must be absolute' >&2; exit 1; }
[[ "$out" != "$repo" && "$out" != "$repo/"* && "$repo" != "$out/"* ]] || { echo 'Output cannot contain or be inside the source repo.' >&2; exit 1; }
[[ ! -e "$out" ]] || { echo "Output already exists: $out (refusing to mix with stale files)" >&2; exit 1; }
filters=(
  --exclude='.git/'
  --exclude='home/.config/quickshell/backups/'
  --exclude='home/.config/*/logs/'
  --exclude='home/.config/**/logs/'
  --exclude='home/.config/fish/fish_variables'
  --exclude='home/.config/wordcraft/control-key.local-*'
  --exclude='home/.local/share/impasto/camera/sample.jpg'
  --exclude='*.log'
  --exclude='*.log.*'
  --exclude='*.bak'
  --exclude='*.bak-*'
  --exclude='*.pem'
  --exclude='*.key'
  --exclude='id_rsa'
  --exclude='id_ed25519'
)
if (( ! apply )); then
  echo 'DRY RUN: export to' "$out"
  rsync -a --dry-run --stats "${filters[@]}" "$repo/" "$out/"
  echo 'To create it, run ./export-safe.sh --apply'
  exit 0
fi
mkdir -p "$out"
chmod 700 "$out"
rsync -a --stats "${filters[@]}" "$repo/" "$out/"
echo "Export created: $out"
echo 'IMPORTANT: No automatic Git upload. Manually review private data and license permissions before sharing.'
echo "Run: cd '$out' && ./check-repo.sh"
