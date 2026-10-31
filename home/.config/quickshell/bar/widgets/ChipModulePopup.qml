import QtQuick
import Quickshell.Widgets
import "../../theme"
import "../../services"
import "../../components"
import "../island"
import "ChipPanelGeometry.js" as ChipGeometry

// One lazy panel per screen, hosted by the existing bar surface and focus grab.
// The corner touching the bar stays pinned to the source chip throughout the morph.
FocusScope {
 id:root
 property string chipId:""
 property string side:"left"
 property var chipConfiguration:({width:36,height:36,style:"circle",iconScale:100})
 property var barConfiguration:SettingsService
 property rect sourceRect:Qt.rect(0,8,36,36)
 property size viewport:Qt.size(1920,1080)
 property bool opened:false
 property real progress:0
 readonly property string moduleId:({internet:"network",speaker:"volume"})[chipId]||chipId
 readonly property string designId:chipId==="workspaces"?"overview":moduleId
 readonly property var appearance:SettingsService.moduleAppearance[designId]||{}
 readonly property real padding:appearance.padding??(chipId==="workspaces"?Theme.panelPadding:Theme.cardInset)
 readonly property var nativeSize:chipId===""?{width:36,height:36}:chipId==="workspaces"?{width:1560,height:72+Math.ceil(Math.max(1,HyprlandService.maximum)/5)*190}:ModuleService.openSize(moduleId)
 readonly property var desiredSize:({width:nativeSize.width*(appearance.widthScale??100)/100+padding*2,height:nativeSize.height*(appearance.heightScale??100)/100+padding*2})
 readonly property var placement:ChipGeometry.geometry(side,sourceRect,desiredSize,viewport,Math.max(0,progress),8)
 readonly property var motion:SettingsService.moduleMotion(designId)
 readonly property real pace:SettingsService.gameMode?0:motion.followShell?Theme.motion:1
 readonly property int openDuration:Math.round((motion.engine==="spring"?(motion.spring?.panelDuration??SettingsService.shellSpring.panelDuration):motion.followShell?SettingsService.shellExpandDuration:motion.openDuration??280)*pace)
 readonly property int closeDuration:Math.round((motion.engine==="spring"?(motion.spring?.moduleCloseDuration||motion.spring?.closeDuration||SettingsService.shellSpring.closeDuration):motion.followShell?SettingsService.shellExpandDuration:motion.closeDuration??240)*pace)
 readonly property real contentReveal:Math.max(0,Math.min(1,(progress-.16)/.5))
 readonly property real panelRadius:SettingsService.moduleRadius(designId,Theme.radiusLarge)
 readonly property real sourceRadius:chipConfiguration.style==="rounded"?10:Math.min(sourceRect.width,sourceRect.height)/2
 readonly property real radius:sourceRadius+(panelRadius-sourceRadius)*Math.min(1,Math.max(0,progress))
 x:placement.x;y:placement.y;width:placement.width;height:placement.height
 visible:chipId!==""&&(opened||progress>.001)
 enabled:opened
 function openChip(id:string,side:string,configuration:var):void {
  if(chipId===id&&opened){close();return}
  animation.stop()
  if(chipId!==id)progress=0
  chipId=id;root.side=side;chipConfiguration=configuration
  ModuleService.openHost="chip";ModuleService.openId=moduleId
  opened=true;animateTo(1)
  root.forceActiveFocus()
 }
 function animateTo(value:real):void {animation.stop();animation.to=value;animation.duration=value===1?openDuration:closeDuration;animation.start()}
 function clear():void {const id=moduleId;chipId="";if(ModuleService.openHost==="chip"&&ModuleService.openId===id)ModuleService.close()}
 function close(immediate=false) {
  opened=false
  if(immediate||pace===0){animation.stop();progress=0;clear()}
  else if(chipId!=="")animateTo(0)
 }
 NumberAnimation {id:animation;target:root;property:"progress";easing.type:Easing.OutCubic;onFinished:if(!root.opened)root.clear()}
 Keys.onEscapePressed:event=>{root.close();event.accepted=true}
 Connections {target:ModuleService;function onOpenIdChanged(){if(root.opened&&ModuleService.openHost===""&&ModuleService.openId==="")root.close()}}
 ClippingRectangle {
  anchors.fill:parent;radius:root.radius;antialiasing:true;contentUnderBorder:true
  color:Theme.moduleColour(root.designId,"background",Theme.islandGround)
  border.width:Theme.solid?0:1;border.color:Theme.rimOf(Theme.surfaceStyle)
  MouseArea {anchors.fill:parent;acceptedButtons:Qt.AllButtons;cursorShape:Qt.ArrowCursor}
  Loader {
   id:content
   active:root.chipId!==""
   x:root.side==="left"?parent.width-width-root.padding:root.padding;y:root.padding
   width:Math.max(1,root.placement.targetWidth-2*root.padding)
   height:Math.max(1,root.placement.targetHeight-2*root.padding)
   opacity:root.contentReveal;enabled:root.opened&&root.progress>.7
   sourceComponent:root.chipId==="workspaces"?overview:detail
   onLoaded:if(root.opened)item.forceActiveFocus()
   ModuleElementStyler {target:content.item;moduleId:root.designId}
  }
  Loader {
   active:root.visible&&root.progress<.67;enabled:false
   x:root.side==="left"?parent.width-width:0;y:0
   width:root.sourceRect.width;height:root.sourceRect.height
   opacity:1-root.contentReveal
   sourceComponent:IndividualIslandChip {chipId:root.chipId;configuration:root.chipConfiguration;barConfiguration:root.barConfiguration;preview:true}
  }
 }
 Component {id:detail;DetailFace {moduleId:root.moduleId;onClosed:root.close()}}
 Component {id:overview;OverviewPanel {onClosed:root.close()}}
}
