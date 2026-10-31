#!/usr/bin/env python3
"""Open an owned WordCraft window and save edited originals through its control API.

Never rewrites an unedited document, changes formats, intercepts Escape, changes
preferences, or terminates the editor. The small bridge only lives while that
editor document is open. Unsupported/read-only formats retain WordCraft's normal
Save and unsaved-change prompts.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import selectors
import socket
import subprocess
import sys
import time

NATIVE_AUTOSAVE = {'.docx', '.odt', '.rtf'}

class ControlError(RuntimeError):
    pass

class Bridge:
    """The installed CLI handles the local control server's random-key auth."""
    def __init__(self, port: int, timeout: float = 8):
        self.timeout = timeout
        self.sequence = 0
        self.buffer = bytearray()
        self.process = subprocess.Popen(
            ['/usr/bin/wordcraft-cli', 'mcp', '--connect', f'127.0.0.1:{port}'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            start_new_session=True)
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.process.stdout, selectors.EVENT_READ)
        try:
            self.request('initialize', {'protocolVersion': '2024-11-05',
                'capabilities': {}, 'clientInfo': {'name': 'hyprland-document-library', 'version': '1'}})
            self._write({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
        except Exception:
            self.close()
            raise

    def _write(self, value):
        self.process.stdin.write((json.dumps(value, separators=(',', ':')) + '\n').encode())
        self.process.stdin.flush()

    def request(self, method: str, params: dict):
        self.sequence += 1
        request_id = self.sequence
        self._write({'jsonrpc': '2.0', 'id': request_id, 'method': method, 'params': params})
        deadline = time.monotonic() + self.timeout
        while time.monotonic() < deadline:
            while b'\n' in self.buffer:
                raw, _, rest = self.buffer.partition(b'\n')
                self.buffer = bytearray(rest)
                if not raw.strip():
                    continue
                response = json.loads(raw)
                if response.get('id') == request_id:
                    if 'error' in response:
                        raise ControlError('The editor rejected a control request')
                    return response.get('result', {})
            if not self.selector.select(max(0.01, deadline-time.monotonic())):
                break
            data = os.read(self.process.stdout.fileno(), 65536)
            if not data:
                raise ControlError('The editor control bridge closed')
            self.buffer.extend(data)
        raise ControlError('The editor did not respond before the deadline')

    def tool(self, name: str, arguments: dict | None = None):
        result = self.request('tools/call', {'name': name, 'arguments': arguments or {}})
        if result.get('isError'):
            raise ControlError('The editor could not complete the requested operation')
        payload = ''.join(item.get('text', '') for item in result.get('content', []) if item.get('type') == 'text')
        try:
            return json.loads(payload)
        except ValueError as error:
            raise ControlError('The editor returned an unexpected response') from error

    def info(self):
        return self.tool('execute', {'command': 'file.info', 'params': {}})

    def close(self):
        if hasattr(self, 'selector'):
            self.selector.close()
        if getattr(self, 'process', None) is not None:
            self.process.terminate()
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()


def event(kind: str, **values):
    print(json.dumps({'event': kind, **values}), flush=True)


def free_loopback_port():
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        return listener.getsockname()[1]


def save_edited_original(bridge: Bridge, original: str):
    """Do not save another tab/document or even rewrite an untouched original."""
    info = bridge.info()
    if not isinstance(info, dict) or not info.get('path'):
        raise ControlError('No document is open in the owned editor')
    if str(Path(info['path']).resolve()) != original:
        raise ControlError('The editor changed to a different document')
    if info.get('dirty') is not True:
        return False
    # Omit a destination so WordCraft preserves path, format and encryption.
    result = bridge.tool('save_document')
    if not isinstance(result, dict) or result.get('saved') is not True:
        raise ControlError('The editor did not confirm a successful save')
    if str(Path(result.get('path', '')).resolve()) != original:
        raise ControlError('The editor saved to an unexpected path')
    verified = bridge.info()
    if str(Path(verified.get('path', '')).resolve()) != original:
        raise ControlError('The editor changed to a different document')
    if verified.get('dirty') is True:
        # Typing can race the save. The next polling pass safely saves those edits.
        return False
    return True


def open_document(path: str):
    if not os.path.isabs(path):
        raise ValueError('Pass an absolute document path')
    original = str(Path(path).resolve(strict=True))
    if not Path(original).is_file():
        raise ValueError('The document is not a regular file')
    supported = Path(original).suffix.lower() in NATIVE_AUTOSAVE and os.access(original, os.W_OK)
    port = free_loopback_port() if supported else None
    command = ['/usr/bin/wordcraft'] + (['--control', str(port)] if port else []) + [original]
    editor = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL, start_new_session=True)
    event('opened', pid=editor.pid, port=port, autosave='enabled' if supported else 'manual')
    # Lower only the helper/bridge priority, after the GUI has been launched.
    try:
        if os.getpriority(os.PRIO_PROCESS, 0) < 10:
            os.setpriority(os.PRIO_PROCESS, 0, 10)
    except (OSError, AttributeError):
        pass
    if not supported:
        return 0
    bridge = None
    try:
        deadline = time.monotonic() + 12
        while editor.poll() is None and time.monotonic() < deadline:
            try:
                with socket.create_connection(('127.0.0.1', port), timeout=0.15):
                    break
            except OSError:
                time.sleep(.1)
        if editor.poll() is not None:
            return 0
        bridge = Bridge(port)
        first_saved = False
        while editor.poll() is None:
            if save_edited_original(bridge, original):
                if not first_saved:
                    event('autosave-confirmed', pid=editor.pid)
                    first_saved = True
            time.sleep(2)
        return 0
    except (OSError, ValueError, ControlError, BrokenPipeError):
        # Do not close or kill the GUI: its normal prompts protect unsaved work.
        event('manual-save-required', pid=editor.pid)
        return 0
    finally:
        if bridge:
            bridge.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['open'])
    parser.add_argument('path')
    args = parser.parse_args()
    try:
        return open_document(args.path)
    except (OSError, ValueError) as error:
        print(json.dumps({'event': 'error', 'message': str(error)}), file=sys.stderr)
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
