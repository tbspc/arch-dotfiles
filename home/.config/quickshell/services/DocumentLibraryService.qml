pragma Singleton
import QtQuick
import Quickshell
QtObject {
    id:root
    signal fullscreenRequested()
    function openDocument(path:string):void {
        if(!path || !path.startsWith("/"))return
        const extension=path.split(".").pop().toLowerCase()
        const app=({pdf:"/usr/bin/pdfcraft",pptx:"/usr/bin/deckcraft",deckcraft:"/usr/bin/deckcraft",xlsx:"/usr/bin/gridcraft"})[extension]
        if(app)Quickshell.execDetached([app,path])
        else Quickshell.execDetached([Quickshell.shellPath("scripts/wordcraft_autosave.py"),"open",path])
    }
}
