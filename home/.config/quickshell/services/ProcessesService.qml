pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id:root
    property int subscribers:0
    property var entries:[]
    property var previous:({})
    property real previousTime:0
    property real available:0
    property real total:0
    property string message:""
    readonly property bool busy:snapshot.running||action.running
    function subscribe():void{subscribers++;refresh()}
    function release():void{subscribers=Math.max(0,subscribers-1)}
    function refresh():void{if(subscribers>0&&!snapshot.running)snapshot.running=true}
    function close(entry:var,force:bool):void{if(!entry||entry.protected||action.running)return;action.command=[Quickshell.shellPath("scripts/processes.py"),"close",JSON.stringify(entry.processes),force?"force":"normal"];action.running=true}
    function memory(kib:real):string{return kib>=1048576?(kib/1048576).toFixed(2)+" GiB":(kib/1024).toFixed(0)+" MiB"}
    readonly property Timer timer:Timer{interval:2000;running:root.subscribers>0;repeat:true;onTriggered:root.refresh()}
    readonly property Process snapshot:Process{
        command:[Quickshell.shellPath("scripts/processes.py")]
        stdout:StdioCollector{onStreamFinished:{
            try{
                const data=JSON.parse(text),old=root.previous,elapsed=data.time-root.previousTime,next={}
                if(!data.entries)return
                root.entries=data.entries.map(entry=>{
                    next[entry.id]=entry.ticks
                    const used=old[entry.id]===undefined||elapsed<=0?0:Math.max(0,(entry.ticks-old[entry.id])/data.ticksPerSecond/elapsed/data.cpus*100)
                    return Object.assign({},entry,{cpu:used})
                })
                root.previous=next;root.previousTime=data.time;root.available=data.available;root.total=data.total
            }catch(error){root.message=String(error)}
        }}
    }
    readonly property Process action:Process{
        stdout:StdioCollector{onStreamFinished:{try{const result=JSON.parse(text);root.message=result.message||""}catch(error){root.message=String(error)}root.refresh()}}
    }
}
