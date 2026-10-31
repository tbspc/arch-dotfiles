import QtQuick
import Quickshell.Io
QtObject {
 id:root
 property bool testing:false
 property bool ready:false
 property bool closing:false
 property int revision:0
 property int readerRevision:0
 readonly property int textSize:Number(values["settingsDesign:controlFontSize"]||13)
 property var values:({})
 property var themes:[]
 property var shellMotionPresets:[]
 property var windowMotionPresets:[]
 property string theme:""
 property color accent:"#9fc597"
 property string error:""
 property bool burst:false
 property var pending:({})
 property var active:({})
 readonly property string mainPath:"/home/tbs/.config/quickshell"
 function get(field){return values[field.id]===undefined?field.default:values[field.id]}
 function set(field,value){revision++;values=Object.assign({},values,{[field.id]:value});if(testing)return;pending=Object.assign({},pending,{[field.id]:JSON.stringify(value)});flush.restart()}
 function action(id){
 var parts=id.split(":");
 if(parts[0]==="editor"){send("module-editor","open",[]);send("module-design","selectModule",[parts[1]])}
 else if(parts[0]==="advanced")send("settings","open",[parts[1],parts[2]||""]);
 else if(id==="wallpaper")send("panel","open",["appearance"]);
 }
 function send(target,method,args){revision++;queue.push([target,method,args||[]]);pump()}
 property var queue:[]
 function pump(){if(writer.running||!queue.length)return;var task=queue.shift();writer.command=["quickshell","ipc","-p",mainPath,"call",task[0],task[1]].concat(task[2]);writer.running=true}
 function refresh(){if(!testing&&!reader.running&&!writer.running&&!Object.keys(pending).length){readerRevision=revision;reader.running=true}}
 function accept(text){if(readerRevision!==revision||Object.keys(pending).length||queue.length)return;try{const d=JSON.parse(text);if(!d.ready){error="Waiting for your shell…";return}values=d.values;themes=d.themes;shellMotionPresets=d.shellMotionPresets||[];windowMotionPresets=d.windowMotionPresets||[];theme=d.theme;accent=d.accent;burst=d.burst;ready=true;error=""}catch(e){error="Could not connect to your running shell"}}
 function flushPending(){for(var id in pending)queue.push(["settings","studioSet",[id,pending[id]]]);pending=({});pump()}
 function requestClose(){closing=true;flush.stop();flushPending();if(!writer.running&&!queue.length)Qt.quit()}
 readonly property Timer flush:Timer{interval:100;onTriggered:root.flushPending()}
 readonly property Timer poll:Timer{interval:2000;repeat:true;running:!root.testing;triggeredOnStart:true;onTriggered:root.refresh()}
 readonly property Process reader:Process{command:["quickshell","ipc","-p",root.mainPath,"call","settings","studioSnapshot"];stdout:StdioCollector{onStreamFinished:root.accept(text)}}
 readonly property Process writer:Process{stdout:StdioCollector{onStreamFinished:{var result=text.trim();if(result&&result!=="ok"){try{var d=JSON.parse(result);if(d.error)root.error=d.error}catch(e){root.error=result}}}}
onExited:(code,status)=>{if(code!==0)root.error="Change could not be applied; your previous setting was kept";if(root.queue.length)Qt.callLater(root.pump);else if(root.closing)Qt.quit();else Qt.callLater(root.refresh)}}
 Component.onCompleted:if(testing){ready=true;accent="#9fc597";themes=[{id:"noir",name:"Noir",swatches:[]}];theme="noir"}
}
