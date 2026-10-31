#!/usr/bin/env bash
# Read-only audit: does not print matching secret lines.
set -euo pipefail
repo=$(cd -- "$(dirname -- "$(realpath -- "$0")")" && pwd)
[[ -d "$repo/home" ]] || { echo 'Missing home/'; exit 1; }
echo '=== CAPTURE SIZE ==='
du -sh "$repo/home"
echo '=== SENSITIVE FILE PATHS (review, exclude from export) ==='
find "$repo/home" -type f \( -name 'fish_variables' -o -name 'control-key.local-*' -o -name '*.pem' -o -name '*.key' -o -name 'id_rsa' -o -name 'id_ed25519' -o -name '*.log' \) -print | head -40 || true
echo '=== ABSOLUTE HOME REFERENCES (filenames only) ==='
old_home=$(cat "$repo/metadata/source-home.txt" 2>/dev/null || true)
if [[ -n "$old_home" ]]; then
  grep -RIlF --exclude-dir=backups -- "$old_home" "$repo/home/.config/hypr" "$repo/home/.config/quickshell" "$repo/home/.local/share/applications" "$repo/home/.local/bin" 2>/dev/null | head -60 || true
else
  echo 'metadata/source-home.txt missing; run ./prepare-source.sh on original laptop.'
fi
echo '=== BROKEN SYMLINKS ==='
find "$repo/home" -xtype l -print | head -40 || true
echo '=== FILES >=90 MiB ==='
find "$repo/home" -type f -size +90M -printf '%s %p\n' | head -40 || true
echo '=== IMPASTO CAPTURE ==='
for rel in .config/hypr .config/quickshell .config/sane-settings .local/share/impasto .local/bin/impasto; do
  [[ -e "$repo/home/$rel" ]] && echo "OK $rel" || echo "MISSING $rel"
done
echo '=== HEURISTIC CREDENTIAL FLAGS (filenames only, false positives possible) ==='
if [[ -d "$repo/home/.config" ]]; then
  grep -RIlEi --exclude-dir=backups --exclude='*.log' '(api[_-]?key|access[_-]?token|password[[:space:]]*[=:]|client[_-]?secret)' "$repo/home/.config" 2>/dev/null | head -50 || true
fi
echo 'This is not a conclusive secrets scanner. Review all files before sharing.'
