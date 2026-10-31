#!/usr/bin/env python3
from pathlib import Path
import sys,json,re,subprocess,ctypes,os,tempfile
home=Path.home();config=home/'.config';themes={'macos-classic':'macOS','tahoe':'macos-tahoe-cursor','bibata':'Bibata-Modern-Ice','adwaita':'Adwaita'}
if len(sys.argv)>1 and sys.argv[1]=='--restore':
 try:v=json.loads((home/'.local/state/quickshell/settings.json').read_text())
 except (OSError,ValueError):v={}
 style=v.get('cursorStyle','tahoe');size=int(v.get('cursorSize',24))
else:style=sys.argv[1] if len(sys.argv)>1 else 'tahoe';size=int(sys.argv[2]) if len(sys.argv)>2 else 24
size=max(16,min(64,size));theme=themes.get(style,themes['tahoe'])
def write(p,text):
 p.parent.mkdir(parents=True,exist_ok=True)
 if p.exists() and p.read_text()==text:return
 fd,tmp=tempfile.mkstemp(prefix='.cursor-',dir=p.parent)
 with os.fdopen(fd,'w') as f:f.write(text)
 os.replace(tmp,p)
def run(args):return subprocess.run(args,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
for version in ['gtk-3.0','gtk-4.0']:
 p=config/version/'settings.ini';text=p.read_text() if p.exists() else '[Settings]\n'
 for key,value in [('gtk-cursor-theme-name',theme),('gtk-cursor-theme-size',str(size))]:
  if re.search(r'^'+key+r'=.*$',text,re.M):text=re.sub(r'^'+key+r'=.*$',key+'='+value,text,flags=re.M)
  else:text=text.replace('[Settings]','[Settings]\n'+key+'='+value,1)
 write(p,text)
for p in [home/'.icons/default/index.theme',home/'.local/share/icons/default/index.theme']:write(p,'[Icon Theme]\nInherits='+theme+'\n')
write(config/'environment.d/20-impasto-cursor.conf',f'XCURSOR_THEME={theme}\nXCURSOR_SIZE={size}\nHYPRCURSOR_THEME={theme}\nHYPRCURSOR_SIZE={size}\n')
write(config/'hypr/modules/cursor_choice.lua',f'hl.env("XCURSOR_THEME", "{theme}")\nhl.env("HYPRCURSOR_THEME", "{theme}")\nhl.env("XCURSOR_SIZE", "{size}")\nhl.env("HYPRCURSOR_SIZE", "{size}")\n-- These installed themes are Xcursor themes. Use them directly from startup.\nhl.config({{ cursor = {{ enable_hyprcursor = false }} }})\n')
for key,value in [('cursor-theme',theme),('cursor-size',str(size))]:run(['gsettings','set','org.gnome.desktop.interface',key,value])
run(['systemctl','--user','set-environment',f'XCURSOR_THEME={theme}',f'HYPRCURSOR_THEME={theme}',f'XCURSOR_SIZE={size}',f'HYPRCURSOR_SIZE={size}'])
run(['hyprctl','eval',f'hl.env("XCURSOR_THEME","{theme}"); hl.env("HYPRCURSOR_THEME","{theme}"); hl.env("XCURSOR_SIZE","{size}"); hl.env("HYPRCURSOR_SIZE","{size}")'])
# Avoid the native-theme loader and its fallback to a different installed theme.
run(['hyprctl','eval','hl.config({ cursor = { enable_hyprcursor = false } })'])
run(['hyprctl','setcursor',theme,str(size)])
try:
 x=ctypes.CDLL('libX11.so.6');x.XOpenDisplay.argtypes=[ctypes.c_char_p];x.XOpenDisplay.restype=ctypes.c_void_p;d=x.XOpenDisplay(None)
 if d:
  x.XDefaultRootWindow.argtypes=[ctypes.c_void_p];x.XDefaultRootWindow.restype=ctypes.c_ulong
  x.XInternAtom.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int];x.XInternAtom.restype=ctypes.c_ulong
  x.XResourceManagerString.argtypes=[ctypes.c_void_p];x.XResourceManagerString.restype=ctypes.c_char_p
  text=(x.XResourceManagerString(d) or b'').decode(errors='replace');text=re.sub(r'^Xcursor\.(theme|size):.*\n?','',text,flags=re.M).strip()+f'\nXcursor.theme: {theme}\nXcursor.size: {size}\n';raw=text.encode()
  x.XChangeProperty.argtypes=[ctypes.c_void_p,ctypes.c_ulong,ctypes.c_ulong,ctypes.c_ulong,ctypes.c_int,ctypes.c_int,ctypes.c_char_p,ctypes.c_int]
  x.XChangeProperty(d,x.XDefaultRootWindow(d),x.XInternAtom(d,b'RESOURCE_MANAGER',False),x.XInternAtom(d,b'STRING',False),8,0,raw,len(raw))
  xc=ctypes.CDLL('libXcursor.so.1')
  xc.XcursorSetTheme.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
  xc.XcursorSetDefaultSize.argtypes=[ctypes.c_void_p,ctypes.c_int]
  xc.XcursorLibraryLoadCursor.argtypes=[ctypes.c_void_p,ctypes.c_char_p];xc.XcursorLibraryLoadCursor.restype=ctypes.c_ulong
  xc.XcursorSetTheme(d,theme.encode());xc.XcursorSetDefaultSize(d,size)
  cursor=xc.XcursorLibraryLoadCursor(d,b'left_ptr')
  if cursor:
   x.XDefineCursor.argtypes=[ctypes.c_void_p,ctypes.c_ulong,ctypes.c_ulong]
   x.XDefineCursor(d,x.XDefaultRootWindow(d),cursor)
   x.XFreeCursor.argtypes=[ctypes.c_void_p,ctypes.c_ulong];x.XFreeCursor(d,cursor)
  x.XFlush.argtypes=[ctypes.c_void_p];x.XFlush(d)
  x.XCloseDisplay.argtypes=[ctypes.c_void_p];x.XCloseDisplay(d)
except (OSError,AttributeError):pass
print('Cursor defaults:',theme,size)
