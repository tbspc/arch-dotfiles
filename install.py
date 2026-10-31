#!/usr/bin/env python3
"""Safely restore user-space dotfiles, never system/boot files."""
import argparse
import datetime as dt
import filecmp
import hashlib
import os
import shutil
import stat
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
SOURCE = REPO / 'home'
HOME = Path.home()
BACKUP_BASE = HOME / '.local/state/arch-dotfiles-backups'
TEXT_EXTENSIONS = {
    '.qml', '.lua', '.json', '.ini', '.conf', '.desktop', '.fish', '.sh',
    '.toml', '.yaml', '.yml', '.ron', '.py', '.js', '.css', '.xml', '.md',
    '.txt', '.service', '.target', '.socket', '.timer', '.rules', '.theme',
    '.cfg', '.properties', '.bashrc', '.zshrc', '.profile', '.list',
}
SKIP_PARTS = {'.git', '.cache', '__pycache__'}
SKIP_NAMES = {'fish_variables'}


def iter_files(root):
    for base, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_PARTS)
        for d in list(dirs):
            p = Path(base) / d
            if p.is_symlink():
                dirs.remove(d)
                yield p
        for name in sorted(files):
            if name not in SKIP_NAMES:
                yield Path(base) / name


def source_home():
    file = REPO / 'metadata/source-home.txt'
    if file.exists():
        return file.read_text(encoding='utf-8').strip()
    return ''


def portable_content(src, orig_home):
    if src.is_symlink():
        link = os.readlink(src)
        if orig_home and link.startswith(orig_home + '/'):
            link = str(HOME) + link[len(orig_home):]
        return ('link', link)
    data = src.read_bytes()
    if (orig_home and orig_home != str(HOME) and
            (src.suffix.lower() in TEXT_EXTENSIONS or src.name in {'.bashrc', '.zshrc', '.profile'}) and
            len(data) <= 5_000_000 and b'\0' not in data):
        try:
            data = data.decode('utf-8').replace(orig_home, str(HOME)).encode('utf-8')
        except UnicodeDecodeError:
            pass
    return ('bytes', data)


def matches(dest, kind, content):
    if kind == 'link':
        return dest.is_symlink() and os.readlink(dest) == content
    if dest.is_symlink() or not dest.is_file():
        return False
    if dest.stat().st_size != len(content):
        return False
    # Avoid copying if identical; hash comparison reads both files.
    with dest.open('rb') as f:
        for offset in range(0, len(content), 1_048_576):
            if f.read(1_048_576) != content[offset:offset + 1_048_576]:
                return False
        return f.read(1) == b''


def unsafe_parent(dest):
    parent = dest.parent
    while parent != HOME.parent:
        if parent.is_symlink():
            return parent
        if parent == HOME:
            break
        parent = parent.parent
    return None


def copy_backup(dest, backup):
    backup.parent.mkdir(parents=True, exist_ok=True)
    if dest.is_symlink():
        backup.symlink_to(os.readlink(dest))
    else:
        shutil.copy2(dest, backup)


def restore(src, dst, kind, content):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink() or dst.is_file():
        dst.unlink()
    if kind == 'link':
        dst.symlink_to(content)
    else:
        with dst.open('wb') as f:
            f.write(content)
        shutil.copymode(src, dst)


def main():
    p = argparse.ArgumentParser(description='Restore home/ configs with backups and home-path portability')
    p.add_argument('--apply', action='store_true', help='actually restore files (default: preview only)')
    p.add_argument('--yes', action='store_true', help='skip interactive confirmation when applying')
    p.add_argument('--verbose', action='store_true', help='list every changed file')
    args = p.parse_args()
    if os.geteuid() == 0:
        sys.exit('Do not run as root or with sudo.')
    if not SOURCE.is_dir():
        sys.exit(f'Missing {SOURCE}. Copy these scripts into your captured arch-dotfiles directory first.')
    if not (SOURCE / '.config/hypr').exists() or not (SOURCE / '.local/share/impasto').exists():
        print('WARNING: Hyprland or Impasto is absent from this capture.', file=sys.stderr)
    orig_home = source_home()
    if not orig_home:
        print('WARNING: metadata/source-home.txt not found; old absolute home paths cannot be rewritten.', file=sys.stderr)
    to_install, skipped, conflicts = [], 0, []
    for src in iter_files(SOURCE):
        rel = src.relative_to(SOURCE)
        dst = HOME / rel
        bad_parent = unsafe_parent(dst)
        if bad_parent:
            conflicts.append(f'{rel}: symlinked ancestor {bad_parent}')
            continue
        if dst.exists() and dst.is_dir() and not dst.is_symlink():
            conflicts.append(f'{rel}: directory is in the way')
            continue
        kind, content = portable_content(src, orig_home)
        if matches(dst, kind, content):
            skipped += 1
        else:
            to_install.append((src, rel, dst, kind, content))
    print(f'Source: {SOURCE}\nTarget: {HOME}\nOld home: {orig_home or "(unknown)"}')
    print(f'Already identical: {skipped}; to restore: {len(to_install)}; conflicts: {len(conflicts)}')
    for issue in conflicts[:30]:
        print('  CONFLICT:', issue)
    if len(conflicts) > 30:
        print(f'  ... and {len(conflicts) - 30} more conflicts')
    for _, rel, dst, _, _ in (to_install if args.verbose else to_install[:25]):
        print(f'  {"REPLACE" if dst.exists() or dst.is_symlink() else "NEW"}: {rel}')
    if not args.verbose and len(to_install) > 25:
        print(f'  ... and {len(to_install) - 25} more (use --verbose)')
    if not args.apply:
        print('\nDRY RUN ONLY. Use ./install.sh --apply to restore.')
        return 1 if conflicts else 0
    if conflicts:
        print('Refusing to apply while destination conflicts exist. Resolve them manually.', file=sys.stderr)
        return 2
    if not args.yes:
        print('\nThis changes files in your home directory, backing up replaced files.')
        if input('Type RESTORE to proceed: ').strip() != 'RESTORE':
            print('Cancelled.')
            return 0
    now = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    backup = BACKUP_BASE / now
    count = 0
    for src, rel, dst, kind, content in to_install:
        if dst.exists() or dst.is_symlink():
            copy_backup(dst, backup / rel)
        restore(src, dst, kind, content)
        count += 1
    print(f'\nRestored {count} files. Backups (if any): {backup}')
    print('No system files, boot configuration, or services were changed.')
    print('Next: ./verify.sh')
    return 0


if __name__ == '__main__':
    sys.exit(main())
