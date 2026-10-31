#!/usr/bin/env python3
"""Publish presentation data only; the greeter's authentication is unchanged."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile

STYLE = Path('/var/lib/impasto/login/style.json')
AVATAR = Path('/var/lib/impasto/login/avatar.png')
BOUNDS = {
 'lockIslandWidth': (18, 16384, 150), 'lockIslandHeight': (8, 200, 44),
 'lockIslandTop': (0, 200, 12), 'lockIslandOffset': (-600, 600, 0),
 'lockUnlockDuration': (0, 1200, 0), 'lockAnimationDuration': (200, 1200, 600), 'lockSlideDistance': (30, 360, 110),
 'lockMotion': (0, 3, 1),
 'lockAnimationSpeed': (50, 200, 100), 'lockAnimationBounciness': (0, 100, 40),
 'lockAnimationRebounds': (1, 3, 2),
 'lockClockSize': (60, 260, 168), 'lockDateSize': (10, 40, 22),
 'lockClockTop': (0, 320, 54), 'lockClockOpacity': (20, 100, 100),
 'lockDateOpacity': (10, 100, 78), 'lockClockShadow': (0, 100, 45),
 'lockAvatarSize': (24, 100, 46), 'lockAccountBottom': (0, 360, 12),
 'lockProfileGap': (0, 32, 8), 'lockPromptGap': (4, 60, 32),
 'lockNameSize': (9, 24, 11), 'lockFieldWidth': (140, 400, 210),
 'lockGlassRefraction': (0, 180, 80), 'lockGlassBlur': (0, 22, 5), 'lockGlassTint': (0, 100, 35), 'lockGlassShine': (0, 100, 30),
 'lockFieldHeight': (24, 52, 32), 'lockFieldOpacity': (0, 70, 14),
 'lockFieldBorderOpacity': (0, 100, 34), 'lockDim': (0, 60, 18),
 'lockVibrance': (-100, 100, 42), 'lockBlur': (0, 256, 8), 'lockExtraBlur': (0, 150, 75),
}

def sanitize(source):
    result = {}
    for key, (low, high, default) in BOUNDS.items():
        value = source.get(key, default)
        result[key] = max(low, min(high, value)) if type(value) in (int, float) and value == value else default
    for key in ('lockShowsDate', 'lockStatus', 'lockHint', 'lockIslandEnabled', 'lockIslandNotched'):
        result[key] = source.get(key) if type(source.get(key)) is bool else key not in ('lockIslandEnabled', 'lockIslandNotched')
    for key, choices, default in (
        ('lockBackdrop', ('wallpaper', 'desktop'), 'wallpaper'),
        ('lockDesign', ('original', 'reference'), 'original'),
        ('lockFieldMaterial', ('classic', 'tahoe'), 'classic'),
        ('lockClock', ('inline', 'stacked', 'flip'), 'inline'),
        ('lockUnlockMovement', ('follow', 'smooth', 'glide', 'quint', 'linear'), 'follow'),
        ('lockAnimationMovement', ('smooth', 'glide', 'quint', 'linear', 'spring', 'bounce'), 'smooth'),
        ('lockAnimation', ('fade', 'soft-slide', 'bar-slide', 'none'), 'fade'),
        ('lockTimeFormat', ('HH:mm', 'hh:mm AP', 'h:mm AP'), 'HH:mm'),
    ):
        result[key] = source.get(key) if source.get(key) in choices else default
    for key, default, length in (
        ('lockFontFamily', 'Nunito', 100), ('lockIdleHint', 'Touch ID or Enter Password', 100),
        ('lockPlaceholder', 'Enter Password', 80), ('displayName', '', 128), ('user', '', 64),
    ):
        value = source.get(key, default)
        result[key] = str(value).replace('\x00', '')[:length] if isinstance(value, str) else default
    color = source.get('lockTextColor', '#ffffff')
    result['lockTextColor'] = color if isinstance(color, str) and re.fullmatch(r'#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?', color) else '#ffffff'
    return result

def check_owned(path):
    try:
        info = path.lstat()
    except FileNotFoundError:
        return
    if info.st_uid != os.getuid() or not stat.S_ISREG(info.st_mode):
        raise OSError(f'Refusing to replace a style file not owned by this account: {path}')

def write_atomic(path, data):
    check_owned(path)
    if path.exists() and path.read_bytes() == data:
        return
    fd, temporary = tempfile.mkstemp(prefix='.impasto-lock-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as handle:
            handle.write(data)
            os.fchmod(handle.fileno(), 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)

def publish(source):
    if not isinstance(source, dict):
        raise ValueError("Expected a style object")
    settings = sanitize(source)
    settings['avatar'] = ''
    path = source.get('avatar', '')
    if isinstance(path, str) and os.path.isabs(path) and os.path.isfile(path) and shutil.which('magick'):
        source_path = Path(path)
        if source_path.stat().st_size <= 20 * 1024 * 1024:
            digest = hashlib.sha256(source_path.read_bytes()).hexdigest()[:20]
            old = {}
            if STYLE.is_file() and not STYLE.is_symlink():
                try: old = json.loads(STYLE.read_text()).get('settings', {})
                except (OSError, ValueError): pass
            uri = 'file://' + str(AVATAR) + '#' + digest
            if old.get('avatar') != uri or not AVATAR.is_file():
                check_owned(AVATAR)
                fd, temporary = tempfile.mkstemp(prefix='.impasto-avatar-', suffix='.png', dir=AVATAR.parent)
                os.close(fd)
                try:
                    subprocess.run(['magick', path, '-auto-orient', '-thumbnail', '256x256', temporary], check=True, timeout=10, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                    os.chmod(temporary, 0o644)
                    os.replace(temporary, AVATAR)
                finally:
                    if os.path.exists(temporary): os.unlink(temporary)
            settings['avatar'] = uri
    write_atomic(STYLE, (json.dumps({'schema': 1, 'settings': settings}, sort_keys=True, indent=2) + '\n').encode())

if __name__ == '__main__':
    try:
        publish(json.loads(sys.argv[1]))
    except (OSError, ValueError, IndexError, subprocess.SubprocessError) as error:
        print(f'Cannot publish login styling: {error}', file=sys.stderr)
        sys.exit(1)
