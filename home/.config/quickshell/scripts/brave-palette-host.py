#!/usr/bin/env python3
"""Local native-messaging palette events, sleeping on inotify while idle."""
import ctypes, hashlib, json, os, select, struct, sys
from pathlib import Path
ALLOWED_ORIGIN = 'chrome-extension://gbknebbjkklmcdanompjfbgbbbdfamie/'

def main():
    if len(sys.argv) < 2 or sys.argv[1] != ALLOWED_ORIGIN:
        return 1
    directory = Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'quickshell'
    directory.mkdir(parents=True,exist_ok=True)
    palette = directory/'brave-palette-event.json'
    libc=ctypes.CDLL(None,use_errno=True)
    fd=libc.inotify_init1(os.O_NONBLOCK|os.O_CLOEXEC)
    if fd<0 or libc.inotify_add_watch(fd,os.fsencode(directory),0x00000008|0x00000080)<0:return 1
    def digest():
        try:return hashlib.sha256(palette.read_bytes()).hexdigest()
        except FileNotFoundError:return ''
    def send(kind,token):
        data=json.dumps({'type':kind,'sequence':token},separators=(',',':')).encode()
        sys.stdout.buffer.write(struct.pack('=I',len(data))+data);sys.stdout.buffer.flush()
    previous=digest();send('ready',previous)
    buffer=b''
    try:
        while True:
            available,_,_=select.select([0,fd],[],[])
            if 0 in available:
                block=os.read(0,4096)
                if not block:return 0
                buffer+=block
                while len(buffer)>=4:
                    length=struct.unpack('=I',buffer[:4])[0]
                    if length>4096:return 1
                    if len(buffer)<4+length:break
                    buffer=buffer[4+length:]
            if fd in available:
                events=os.read(fd,65536);offset=0;changed=False
                while offset+16<=len(events):
                    _,_,_,size=struct.unpack_from('iIII',events,offset)
                    name=events[offset+16:offset+16+size].split(b'\0',1)[0]
                    changed=changed or name==palette.name.encode();offset+=16+size
                if changed:
                    current=digest()
                    if current!=previous:previous=current;send('palette',current)
    except (BrokenPipeError,ConnectionResetError):return 0
    finally:os.close(fd)
if __name__=='__main__':raise SystemExit(main())
