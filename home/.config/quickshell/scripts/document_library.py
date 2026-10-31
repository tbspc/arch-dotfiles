#!/usr/bin/python3
"""On-demand, read-only library index and native first-page document thumbnails."""
import argparse
import hashlib
import heapq
import json
import os
from pathlib import Path
import re
import resource
import shlex
import signal
import subprocess
import sys
import time

WORD_EXTENSIONS = {'.docx', '.docm', '.dotx', '.dotm', '.doc', '.odt', '.rtf', '.html', '.htm', '.md', '.markdown', '.tex', '.txt'}
DECK_EXTENSIONS = {'.pptx', '.deckcraft'}
GRID_EXTENSIONS = {'.xlsx'}
EXTENSIONS = WORD_EXTENSIONS | DECK_EXTENSIONS | GRID_EXTENSIONS | {'.pdf'}
SKIP_DIRS = {'node_modules', '__pycache__', 'venv', 'Cache', 'cache'}
CACHE_BYTES = 64 * 1024 * 1024
_CHILD = None


def roots(home=None):
    home = Path(home or Path.home()).resolve()
    directories = {'DOCUMENTS': str(home / 'Documents'), 'DOWNLOAD': str(home / 'Downloads'), 'DESKTOP': str(home / 'Desktop'), 'PROJECTS': str(home / 'Projects')}
    config = Path(os.environ.get('XDG_CONFIG_HOME', str(home / '.config'))) / 'user-dirs.dirs'
    try:
        for line in config.read_text(encoding='utf-8').splitlines():
            match = re.match(r'^\s*XDG_(DOCUMENTS|DOWNLOAD|DESKTOP)_DIR\s*=\s*(.*?)\s*$', line)
            if not match:
                continue
            try:
                words = shlex.split(match[2], comments=True)
            except ValueError:
                continue
            if len(words) != 1:
                continue
            value = words[0].replace('${HOME}', str(home)).replace('$HOME', str(home))
            if os.path.isabs(value):
                directories[match[1]] = value
    except OSError:
        pass
    seen = set()
    result = []
    for key, ident, label in [('DOCUMENTS', 'documents', 'Documents'), ('DOWNLOAD', 'downloads', 'Downloads'), ('DESKTOP', 'desktop', 'Desktop'), ('PROJECTS', 'projects', 'Projects')]:
        path = Path(directories[key]).resolve()
        if path == home or path in seen:
            continue  # XDG pointing at HOME means that special directory is disabled.
        seen.add(path)
        result.append({'id': ident, 'name': label, 'path': str(path), 'count': 0})
    return result


def preview_kind(path):
    extension = Path(path).suffix.lower()
    return 'pdf' if extension == '.pdf' else 'deckcraft' if extension in DECK_EXTENSIONS else 'gridcraft' if extension in GRID_EXTENSIONS else 'wordcraft'


def scan(search_roots=None, limit=3000):
    search_roots = [dict(item, count=0) for item in (roots() if search_roots is None else search_roots)]
    errors, seen, newest = [], set(), []
    sequence, visited, truncated = 0, 0, False
    for folder in search_roots:
        base = Path(folder['path'])
        if not base.is_dir():
            continue
        def failed(error):
            if len(errors) < 12:
                errors.append(f"Cannot read {error.filename or folder['name']}")
        for current, dirs, files in os.walk(base, followlinks=False, onerror=failed):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in SKIP_DIRS and not Path(current, d).is_symlink()]
            for name in files:
                visited += 1
                if visited > 200000:
                    truncated = True
                    break
                if name.startswith('.') or Path(name).suffix.lower() not in EXTENSIONS:
                    continue
                path = Path(current, name)
                try:
                    if path.is_symlink() or not path.is_file():
                        continue
                    resolved = str(path.resolve())
                    if resolved in seen:
                        continue
                    info = path.stat()
                    seen.add(resolved)
                    folder['count'] += 1
                    sequence += 1
                    document = {'path': resolved, 'name': name, 'folder': folder['id'], 'relative': str(path.relative_to(base)),
                                'extension': path.suffix.lower().lstrip('.'), 'size': info.st_size,
                                'mtime': info.st_mtime, 'previewKind': preview_kind(path)}
                    item = (info.st_mtime_ns, sequence, document)
                    if len(newest) < limit:
                        heapq.heappush(newest, item)
                    else:
                        truncated = True
                        if item[:2] > newest[0][:2]:
                            heapq.heapreplace(newest, item)
                except OSError:
                    continue
            if visited > 200000:
                break
        if visited > 200000:
            errors.append('Scan stopped after 200,000 files; narrow the source folders to show more.')
            break
    return {'roots': search_roots, 'documents': [item[2] for item in sorted(newest, reverse=True)], 'truncated': truncated, 'errors': errors}


def stop_child():
    global _CHILD
    child = _CHILD
    if child is not None and child.poll() is None:
        try:
            os.killpg(child.pid, signal.SIGTERM)
            child.wait(timeout=.25)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            child.wait()
    _CHILD = None


def cancelled(signum, frame):
    stop_child()
    raise SystemExit(128 + signum)


def renderer_limits():
    os.nice(10)
    resource.setrlimit(resource.RLIMIT_AS, (768 * 1024 * 1024,) * 2)
    resource.setrlimit(resource.RLIMIT_CPU, (10, 12))
    resource.setrlimit(resource.RLIMIT_FSIZE, (16 * 1024 * 1024,) * 2)
    # Also reap the native renderer when the controlling shell force-kills us.
    try:
        import ctypes
        ctypes.CDLL(None, use_errno=True).prctl(1, signal.SIGTERM)
    except (OSError, AttributeError):
        pass


def render(command):
    global _CHILD
    _CHILD = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              start_new_session=True, preexec_fn=renderer_limits)
    try:
        _, error = _CHILD.communicate(timeout=15)
        if _CHILD.returncode:
            raise RuntimeError('This document could not be previewed. Open it to view its contents.')
    except subprocess.TimeoutExpired:
        stop_child()
        raise RuntimeError('Preview took too long. Open the document to view it.') from None
    finally:
        stop_child()


def trim_cache(directory, protect):
    entries = []
    for entry in directory.glob('*.png'):
        if not re.fullmatch(r'[a-f0-9]{64}\.png', entry.name):
            continue
        try:
            info = entry.stat()
            entries.append((info.st_mtime_ns, entry, info.st_size))
        except OSError:
            continue
    total = sum(item[2] for item in entries)
    for _, entry, size in sorted(entries):
        if total <= CACHE_BYTES:
            break
        if entry != protect:
            try:
                entry.unlink()
                total -= size
            except OSError:
                pass


def preview(filename, cache_dir=None):
    source = Path(filename)
    kind = preview_kind(source)
    result = {'path': '', 'kind': kind, 'error': ''}
    temporary = None
    temporary_pdf = None
    try:
        if not source.is_absolute() or source.suffix.lower() not in EXTENSIONS or not source.is_file():
            raise RuntimeError('Choose an existing supported document.')
        source = source.resolve()
        info = source.stat()
        key = hashlib.sha256(json.dumps(['library-preview-v2', str(source), info.st_size, info.st_mtime_ns, info.st_ctime_ns]).encode()).hexdigest()
        directory = Path(cache_dir or Path(os.environ.get('XDG_CACHE_HOME', str(Path.home() / '.cache'))) / 'quickshell' / 'document-library')
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        directory.chmod(0o700)
        output = directory / (key + '.png')
        if output.is_file() and output.stat().st_size:
            output.touch()
            result['path'] = str(output)
            return result
        temporary = directory / (key + f'.tmp-{os.getpid()}.png')
        if kind == 'deckcraft':
            if not Path('/usr/bin/deckcraft-cli').is_file():
                raise RuntimeError('DeckCraft preview renderer is unavailable.')
            render(['/usr/bin/deckcraft-cli', 'render', str(source), '--slide', '0', '--scale', '0.3', str(temporary)])
        elif kind == 'gridcraft':
            if not Path('/usr/bin/gridcraft-cli').is_file() or not Path('/usr/bin/pdftoppm').is_file():
                raise RuntimeError('GridCraft preview renderer is unavailable.')
            temporary_pdf = temporary.with_suffix('.pdf')
            render(['/usr/bin/gridcraft-cli', 'convert', str(source), str(temporary_pdf)])
            render(['/usr/bin/pdftoppm', '-f', '1', '-singlefile', '-scale-to-x', '300', '-scale-to-y', '-1', '-png', str(temporary_pdf), str(temporary.with_suffix(''))])
        elif kind == 'pdf':
            if not Path('/usr/bin/pdftoppm').is_file():
                raise RuntimeError('PDF preview renderer is unavailable. Open the document to view it.')
            render(['/usr/bin/pdftoppm', '-f', '1', '-singlefile', '-scale-to-x', '300', '-scale-to-y', '-1', '-png', str(source), str(temporary.with_suffix(''))])
        else:
            if not Path('/usr/bin/wordcraft-cli').is_file():
                raise RuntimeError('WordCraft preview renderer is unavailable.')
            render(['/usr/bin/wordcraft-cli', 'render', str(source), str(temporary), '--page', '1', '--scale', '0.35'])
        if not temporary.is_file() or not temporary.stat().st_size:
            raise RuntimeError('No preview was produced. Open the document to view it.')
        try:
            from PIL import Image
            with Image.open(temporary) as image:
                if image.width > 320 or image.height > 480:
                    image.thumbnail((320, 480), Image.Resampling.LANCZOS)
                    image.save(temporary, format='PNG')
        except ImportError:
            pass
        temporary.chmod(0o600)
        os.replace(temporary, output)
        result['path'] = str(output)
        trim_cache(directory, output)
    except (OSError, ValueError, RuntimeError) as error:
        result['error'] = str(error)
    finally:
        if temporary:
            temporary.unlink(missing_ok=True)
        if temporary_pdf:
            temporary_pdf.unlink(missing_ok=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['scan', 'preview'])
    parser.add_argument('path', nargs='?')
    args = parser.parse_args()
    os.umask(0o077)
    signal.signal(signal.SIGTERM, cancelled)
    signal.signal(signal.SIGINT, cancelled)
    if args.action == 'scan':
        result = scan()
    elif args.path:
        result = preview(args.path)
    else:
        parser.error('preview requires an absolute document path')
    print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    main()
