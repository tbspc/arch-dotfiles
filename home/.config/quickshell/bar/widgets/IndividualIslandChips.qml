import QtQuick
import "../../services"
import "../../theme"
Item {
 id:root
 property var configuration:IslandPresetService.presentation
 property bool preview:false
 property string expandedChipId:""
 signal chipActivated(string id,string side,var configuration)
 property real clockCenter:width/2
 property real clockWidth:120
 property real clockY:Theme.islandTopMargin
 property real clockHeight:Theme.capsuleHeight
 property bool showing:true
 property real externalOpacity:1
 property real reveal:configuration.islandChipsEnabled&&showing?1:0
 readonly property bool wanted:configuration.islandChipsEnabled&&showing
 opacity:reveal*externalOpacity;visible:reveal>.001;enabled:wanted&&reveal>.5
 transform:Translate {y:(1-root.reveal)*-4}
 function updateReveal():void {returnDelay.stop();fade.stop();if(wanted)returnDelay.restart();else{fade.to=0;fade.duration=SettingsService.chipHideDuration;fade.start()}}
 property bool ready:false
 onWantedChanged:if(ready)updateReveal()
 Component.onCompleted:{root.reveal=root.wanted?1:0;root.ready=true}
 Timer {id:returnDelay;interval:SettingsService.chipReturnDelay;onTriggered:{fade.to=1;fade.duration=SettingsService.chipShowDuration;fade.start()}}
 NumberAnimation {id:fade;target:root;property:"reveal";easing.type:Easing.OutCubic}
 property real shoulderClearance:((configuration.notched??(configuration.islandAttached||configuration.barStyle==="bezel"))?Theme.radiusNotch*2:0)
 readonly property real safetyGap:Math.max(4,configuration.islandChipGap??12)+root.shoulderClearance
 function chipRect(id:string):rect {
  const side=IslandChipService.get(id,root.configuration).side,strip=side==="left"?leftStrip:rightStrip;
  const config=IslandChipService.get(id,root.configuration);
  return Qt.rect(strip.x+(strip.placement.positions[id]??0),root.clockY+root.chipY(config),config.width,config.height)
 }
 function activateChip(id:string):bool {
  const config=IslandChipService.get(id,root.configuration)
  if(!root.wanted||!IslandChipService.list(config.side,root.configuration,root.preview).some(e=>e.id===id))return false
  root.chipActivated(id,config.side,config);return true
 }
 function chipY(config):real {return Math.max(8/Math.max(.1,Theme.barScale)-root.clockY,(root.clockHeight-config.height)/2+config.offsetY)}
 function bounds(strip):rect {const list=strip.liveEntries;const top=list.length?Math.min(...list.map(e=>root.chipY(e.config))):0;const bottom=list.length?Math.max(...list.map(e=>root.chipY(e.config)+e.config.height)):clockHeight;return Qt.rect(strip.x,clockY+top,strip.width,Math.max(0,bottom-top))}
 readonly property rect leftBounds:bounds(leftStrip)
 readonly property rect rightBounds:bounds(rightStrip)
 component Strip:Item {
  id:strip
  property string side:"left"
  height:root.clockHeight
  property real gap:Math.max(0,root.configuration.islandChipGap??12)
  property int revision:0
  readonly property var entries:IslandChipService.ids.map(id=>({id,config:IslandChipService.get(id,root.configuration)})).filter(e=>e.config.side===side).sort((a,b)=>a.config.order-b.config.order)
  readonly property var wantedIds:{const ids=IslandChipService.list(side,root.configuration,root.preview).map(e=>e.id);if(root.expandedChipId&&!ids.includes(root.expandedChipId)&&IslandChipService.get(root.expandedChipId,root.configuration).side===side)ids.push(root.expandedChipId);return ids}
  readonly property var liveEntries:{const tick=revision;return entries.filter(e=>{const item=slots.itemAt(IslandChipService.ids.indexOf(e.id));return item?item.occupied:wantedIds.includes(e.id)})}
  readonly property var placement:{
   const tick=revision,active=liveEntries,positions={},sizes={};let natural=0
   for(const e of active){positions[e.id]=natural+e.config.offsetX;sizes[e.id]=e.config.width;natural+=e.config.width+gap}
   const baseWidth=Math.max(0,natural-(active.length?gap:0));let boundary=side==="left"?baseWidth:0
   if(side==="left")for(let i=active.length-1;i>=0;i--){const id=active[i].id;positions[id]=Math.min(positions[id],boundary-sizes[id]);boundary=positions[id]-2}
   else for(const e of active){positions[e.id]=Math.max(positions[e.id],boundary);boundary=positions[e.id]+sizes[e.id]+2}
   const min=active.length?Math.min(...active.map(e=>positions[e.id])):0,max=active.length?Math.max(...active.map(e=>positions[e.id]+sizes[e.id])):0
   for(const id of Object.keys(positions))positions[id]-=min
   return {width:Math.max(0,max-min),positions}
  }
  width:placement.width
  Behavior on width {enabled:!root.preview;NumberAnimation {duration:SettingsService.chipShowDuration;easing.type:Easing.OutCubic}}
  Repeater {
   id:slots;model:IslandChipService.ids
   onItemAdded:strip.revision++;onItemRemoved:strip.revision++
   Item {
    id:slot;required property string modelData
    readonly property var chipConfig:IslandChipService.get(modelData,root.configuration)
    readonly property bool wanted:strip.wantedIds.includes(modelData)
    property real presence:wanted?1:0
    readonly property bool occupied:wanted||presence>.001
    x:strip.placement.positions[modelData]??0;width:chipConfig.width;height:root.clockHeight;opacity:presence;visible:occupied
    Behavior on x {enabled:!root.preview;NumberAnimation {duration:SettingsService.chipShowDuration;easing.type:Easing.OutCubic}}
    Behavior on presence {enabled:!root.preview;NumberAnimation {duration:slot.wanted?SettingsService.chipShowDuration:SettingsService.chipHideDuration;easing.type:Easing.OutCubic}}
    Loader {
     active:slot.occupied && root.configuration.islandChipsEnabled;width:slot.chipConfig.width;height:slot.chipConfig.height
     y:root.chipY(slot.chipConfig);scale:.96+.04*slot.presence;opacity:root.expandedChipId===slot.modelData?0:1
     sourceComponent:IndividualIslandChip {chipId:slot.modelData;configuration:slot.chipConfig;barConfiguration:root.configuration;preview:root.preview;onActivated:root.activateChip(slot.modelData)}
    }
   }
  }
 }
 Strip {id:leftStrip;side:"left";x:root.clockCenter-root.clockWidth/2-width-root.safetyGap;y:root.clockY}
 Strip {id:rightStrip;side:"right";x:root.clockCenter+root.clockWidth/2+root.safetyGap;y:root.clockY}
}
