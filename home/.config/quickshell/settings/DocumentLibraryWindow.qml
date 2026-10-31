import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../services"
import "../bar/island"
PanelWindow {
    id:root
    property bool shown:false
    function open(output:var):void {if(output)root.screen=output;root.shown=true}
    function close():void {root.shown=false}
    visible:root.shown
    color:Theme.background
    exclusionMode:ExclusionMode.Ignore
    WlrLayershell.namespace:"hyprland-document-library"
    WlrLayershell.layer:WlrLayer.Overlay
    WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
    anchors { top:true;bottom:true;left:true;right:true }
    IpcHandler {
        target:"document-library"
        function close():void {root.close()}
        function status():string {return JSON.stringify({open:root.shown,loaded:content.active})}
    }
    Shortcut { sequence:"Escape";context:Qt.WindowShortcut;enabled:root.shown;onActivated:root.close() }
    Connections { target:LockService;function onPendingLockChanged(){if(LockService.pendingLock)root.close()} }
    Loader {
        id:content
        anchors.fill:parent;anchors.margins:Math.min(40,root.width*.03)
        active:root.shown
        sourceComponent:DocumentLibraryPanel {
            fullscreenMode:true
            onClosed:root.close()
            onDocumentRequested:path=>{DocumentLibraryService.openDocument(path);root.close()}
        }
    }
}
