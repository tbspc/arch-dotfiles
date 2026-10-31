#!/usr/bin/env python3
"""Load the matching user-local glass build; retain the installed build for rollback."""
from pathlib import Path
import fcntl,os,subprocess,sys
VERSION='0.11.0-live-profiles4'
base=Path.home()/'.local/lib/hyprland'
patched=base/'hyprglass-live.so'
original=Path('/var/cache/hyprpm/tbs/HyprGlass/hyprglass.so')
def run(*args):return subprocess.run(['hyprctl',*args],capture_output=True,text=True,timeout=12)
def main():
 if not patched.exists():return 0
 lock=Path(os.environ.get('XDG_RUNTIME_DIR','/tmp'))/'impasto-glass-loader.lock'
 with lock.open('w') as handle:
  fcntl.flock(handle,fcntl.LOCK_EX)
  listing=run('plugin','list').stdout
  if 'Version: '+VERSION in listing:return 0
  version=run('version').stdout
  if 'efb50993780079460b0cbed1363e2166a2de1d9f' not in version:
   print('The local glass fix needs rebuilding for this Hyprland version; keeping the packaged plugin.',file=sys.stderr);return 1
  if 'Plugin hyprglass by' in listing:
   result=run('plugin','unload',str(patched if 'live-profiles' in listing else original))
   if result.returncode or 'ok' not in result.stdout.lower():
    print('Could not switch the glass plugin: '+result.stdout+result.stderr,file=sys.stderr);return 1
  result=run('plugin','load',str(patched))
  if result.returncode or 'Version: '+VERSION not in run('plugin','list').stdout:
   run('plugin','load',str(original))
   print('Restored the packaged glass plugin after a load error: '+result.stdout+result.stderr,file=sys.stderr);return 1
 return 0
if __name__=='__main__':raise SystemExit(main())
