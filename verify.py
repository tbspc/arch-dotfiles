#!/usr/bin/env python3
"""Validate captured files and restored destination without changing anything."""
import argparse
import os
import shutil
import sys
from pathlib import Path
from install import SOURCE, HOME, iter_files, portable_content, matches, source_home

NEEDED = [
    '.config/hypr', '.config/quickshell', '.config/fish',
    '.config/sane-settings', '.local/share/impasto', '.local/bin/impasto',
]
COMMANDS = ['hyprctl', 'quickshell', 'fish', 'starship', 'kitty', 'python3']

def main():
    a = argparse.ArgumentParser()
    a.add_argument('--source', action='store_true', help='verify capture has required Impasto files')
    a.add_argument('--installed', action='store_true', help='compare all captured files to current home')
    args = a.parse_args()
    if not args.source and not args.installed:
        args.source = True
        args.installed = True
    missing = [r for r in NEEDED if not (SOURCE / r).exists()]
    print('Required capture components:')
    for r in NEEDED:
        print(f'  {"MISSING" if r in missing else "OK"}: {r}')
    print('Available commands on this machine:')
    for c in COMMANDS:
        print(f'  {"OK" if shutil.which(c) else "NOT FOUND"}: {c}')
    if args.installed:
        diffs = []
        count = 0
        old_home = source_home()
        for src in iter_files(SOURCE):
            rel = src.relative_to(SOURCE)
            target = HOME / rel
            kind, value = portable_content(src, old_home)
            count += 1
            if not matches(target, kind, value):
                diffs.append(str(rel))
        print(f'Installed file comparison: {count - len(diffs)}/{count} match')
        for path in diffs[:40]:
            print('  DIFFERENT / MISSING:', path)
        if len(diffs) > 40:
            print(f'  ... {len(diffs) - 40} more differences')
    else:
        diffs = []
    print('NOTE: Matching files do not prove Impasto runtime or camera/GPU features work.')
    return 2 if missing or diffs else 0

if __name__ == '__main__':
    sys.exit(main())
