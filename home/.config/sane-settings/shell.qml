//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray
import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
 Backend{id:backend}
 FloatingWindow {
  id:window;title:"Sane Settings";implicitWidth:782;implicitHeight:720;minimumSize:Qt.size(740,460);color:"#000000";visible:true
  onVisibleChanged:if(!visible)backend.requestClose()
  SettingsView{id:view;anchors.fill:parent;backend:backend}
  Shortcut{sequence:"Ctrl+Q";onActivated:backend.requestClose()}
 }
 IpcHandler{
  target:"studio"
  function show():void{window.visible=true;window.minimized=false;backend.refresh()}
  function select(category:string):void{view.choose(category)}
  function status():string{return JSON.stringify({selected:view.selectedId,ready:backend.ready,error:backend.error,categories:view.categories.map(p=>p.name),controls:view.categories.reduce((n,p)=>n+p.groups.reduce((m,g)=>m+g.rows.length,0),0),queued:backend.queue.length})}
  function preview():bool{return view.grabToImage(result=>result.saveToFile("/tmp/sane-settings-preview.png"))}
  function close():void{backend.requestClose()}
 }
}
