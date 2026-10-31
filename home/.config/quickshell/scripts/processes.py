#!/usr/bin/env python3
"""Owned-process overview and explicit, PID-reuse-safe close actions."""
import json,os,signal,subprocess,sys,time
from collections import defaultdict
from pathlib import Path
PROTECTED={'quickshell','Hyprland','Xwayland','systemd','dbus-broker','dbus-daemon','pipewire','pipewire-pulse','wireplumber','xdg-desktop-portal','xdg-desktop-portal-hyprland','xdg-desktop-portal-gtk'}
def identity(pid):
    p=Path('/proc')/str(pid)
    if p.stat().st_uid!=os.getuid():raise PermissionError('Not your process')
    data=(p/'stat').read_text().rsplit(')',1)[1].split()
    return p,data,int(data[19])
def close(targets,force=False):
    done=0
    for target in targets:
        try:
            p,data,start=identity(int(target['pid']))
            name=(p/'comm').read_text().strip();exe=(p/'exe').readlink().name
            if start!=target['start'] or name in PROTECTED or exe in PROTECTED:continue
            os.kill(int(target['pid']),signal.SIGKILL if force else signal.SIGTERM);done+=1
        except (OSError,ValueError,KeyError):continue
    return {'ok':True,'closed':done,'message':f'Sent {"force quit" if force else "close"} to {done} processes.'}
def snapshot():
    apps={}
    try:
        clients=json.loads(subprocess.run(['hyprctl','-j','clients'],capture_output=True,text=True,timeout=1).stdout)
        for c in clients:
            if c.get('pid',0)>0:apps[c['pid']]=c.get('class') or 'Application'
    except (OSError,ValueError,subprocess.TimeoutExpired):pass
    processes={}
    for p in Path('/proc').glob('[0-9]*'):
        try:
            pid=int(p.name)
            if pid==os.getpid():continue
            _,data,start=identity(pid)
            name=(p/'comm').read_text().strip();exe=(p/'exe').readlink().name
            if name=='MainThread':name=exe
            pss=next(int(l.split()[1]) for l in (p/'smaps_rollup').read_text().splitlines() if l.startswith('Pss:'))
            processes[pid]={'pid':pid,'start':start,'parent':int(data[1]),'name':name,'exe':exe,'memory':pss,'ticks':int(data[11])+int(data[12])}
        except (OSError,ValueError,StopIteration):continue
    groups={}
    labels={'brave-browser':'Brave','chatgpt':'ChatGPT','outlook-for-linux':'Outlook','org.quickshell':'Quickshell'}
    for pid,p in processes.items():
        ancestor=pid;visited=set()
        while ancestor not in apps and ancestor in processes and ancestor not in visited:
            visited.add(ancestor);ancestor=processes[ancestor]['parent']
        app=ancestor in apps
        key='app:'+str(ancestor) if app else 'background:'+p['name']+':'+p['exe']
        if key not in groups:
            label=labels.get(apps[ancestor],apps[ancestor]) if app else p['name']
            groups[key]={'id':key,'name':label,'kind':'apps' if app else 'background','memory':0,'ticks':0,'processes':[],'protected':False}
        group=groups[key];group['memory']+=p['memory'];group['ticks']+=p['ticks']
        group['processes'].append({'pid':pid,'start':p['start']})
        group['protected']=group['protected'] or p['name'] in PROTECTED or p['exe'] in PROTECTED
    memory={}
    for line in Path('/proc/meminfo').read_text().splitlines():
        key,_,value=line.partition(':')
        if key in ['MemTotal','MemAvailable']:memory[key]=int(value.split()[0])
    return {'entries':list(groups.values()),'time':time.monotonic(),'ticksPerSecond':os.sysconf('SC_CLK_TCK'),'cpus':os.cpu_count() or 1,'available':memory.get('MemAvailable',0),'total':memory.get('MemTotal',0)}
if __name__=='__main__':
    try:
        if len(sys.argv)>2 and sys.argv[1]=='close':result=close(json.loads(sys.argv[2]),len(sys.argv)>3 and sys.argv[3]=='force')
        else:result=snapshot()
        print(json.dumps(result,separators=(',',':')))
    except Exception as error:print(json.dumps({'ok':False,'message':str(error)}));raise SystemExit(1)
