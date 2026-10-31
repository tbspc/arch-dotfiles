import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
Item {
 id:root
 required property var field
 required property var backend
 property color accent:backend.accent
 readonly property var current:backend.get(field)
 width:parent?parent.width:540
 implicitHeight:field.type==="slider"?62:field.type==="burst"?56:46
 Rectangle{height:1;x:16;width:parent.width-32;anchors.bottom:parent.bottom;color:"#20201e"}
 Text{x:16;y:field.type==="slider"?12:(parent.height-height)/2;width:field.type==="slider"?parent.width-115:field.type==="burst"?parent.width-80:parent.width*.52;text:field.label;color:"#cecec7";font.family:"Inter";font.pixelSize:backend.textSize;wrapMode:Text.Wrap}
 Loader {
  anchors.fill:parent
  sourceComponent:field.type==="slider"?slider:field.type==="toggle"||field.type==="burst"?toggle:field.type==="choice"||field.type==="themes"?choice:field.type==="text"||field.type==="hex"?edit:field.type==="accent"?swatches:action
 }
 Component{id:slider;Item{
  Text{anchors.right:parent.right;anchors.rightMargin:16;y:12;text:Math.round(control.value)+(field.unit||"");font.family:"Inter";font.pixelSize:11;color:"#929287"}
  Slider{id:control;x:16;y:31;width:parent.width-32;height:24;from:field.min;to:field.max;stepSize:field.key==="barHoverEnlargeAmount"?.5:1;value:Number(root.current);onMoved:backend.set(field,value)
   background:Rectangle{x:control.leftPadding;y:control.topPadding+control.availableHeight/2-2;implicitHeight:4;height:4;width:control.availableWidth;radius:2;color:"#282721";Rectangle{width:control.visualPosition*parent.width;height:parent.height;radius:2;color:root.accent}}
   handle:Rectangle{x:control.leftPadding+control.visualPosition*(control.availableWidth-width);y:control.topPadding+control.availableHeight/2-height/2;width:11;height:11;radius:6;color:root.accent;border.width:1;border.color:"#c3c9af"}
  }
 }}
 Component{id:toggle;Item{Switch{id:sw;anchors.right:parent.right;anchors.rightMargin:15;anchors.verticalCenter:parent.verticalCenter;width:42;height:26;checked:field.type==="burst"?backend.burst:root.current===true;onToggled:field.type==="burst"?backend.send("settings","studioBurst",[checked?"true":"false"]):backend.set(field,checked)
  indicator:Rectangle{width:38;height:21;radius:11;y:(sw.height-height)/2;color:sw.checked?root.accent:"#292925";Rectangle{x:sw.checked?19:3;y:3;width:15;height:15;radius:8;color:sw.checked?"#11130f":"#8b8b83";Behavior on x{NumberAnimation{duration:120;easing.type:Easing.OutCubic}}}}
 }}}
 Component{id:choice;Item{ComboBox{id:combo;anchors.right:parent.right;anchors.rightMargin:16;anchors.verticalCenter:parent.verticalCenter;width:Math.min(235,parent.width*.43);height:32;model:field.type==="themes"?backend.themes.map(t=>({label:t.name,value:t.id})):field.options;textRole:"label";valueRole:"value";currentIndex:model?model.findIndex(o=>o.value===(field.type==="themes"?backend.theme:root.current)):-1;onActivated:field.type==="themes"?backend.send("theme","set",[currentValue]):backend.set(field,currentValue)
  background:Rectangle{color:combo.hovered?"#20201d":"#11110f";radius:8}
  contentItem:Text{leftPadding:10;rightPadding:24;verticalAlignment:Text.AlignVCenter;text:combo.displayText;color:"#aaa99e";font.family:"Inter";font.pixelSize:12;elide:Text.ElideRight}
  indicator:Text{anchors.right:parent.right;anchors.rightMargin:9;anchors.verticalCenter:parent.verticalCenter;text:"⌄";color:"#8a8a80"}
  popup:Popup{y:combo.height+4;width:combo.width;padding:5;implicitHeight:Math.min(310,contentItem.implicitHeight+10);background:Rectangle{color:"#191918";radius:9;border.color:"#35352e"}
   contentItem:ListView{clip:true;implicitHeight:contentHeight;model:combo.popup.visible?combo.delegateModel:null;currentIndex:combo.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator{}}
  }
  delegate:ItemDelegate{width:combo.width-10;height:34;highlighted:combo.highlightedIndex===index;contentItem:Text{text:modelData.label;color:highlighted?"#0b100d":"#cecec7";font.family:"Inter";font.pixelSize:12;elide:Text.ElideRight;verticalAlignment:Text.AlignVCenter}
background:Rectangle{radius:6;color:highlighted?root.accent:"transparent"}}
 }}}
 Component{id:edit;Item{
  TextField{id:input;anchors.right:parent.right;anchors.rightMargin:16;anchors.verticalCenter:parent.verticalCenter;width:Math.min(260,parent.width*.44);height:30;text:field.type==="hex"?String(backend.accent):String(root.current||"");color:"#cecec7";font.family:"Inter";font.pixelSize:backend.textSize;selectByMouse:true;leftPadding:10;rightPadding:10;background:Rectangle{radius:9;color:"#191918";border.width:input.activeFocus?1:0;border.color:root.accent}
onEditingFinished:{if(field.type==="hex"){if(/^#[0-9a-fA-F]{6}$/.test(text))backend.send("settings","studioAccent",[text]);else text=String(backend.accent)}else backend.set(field,text)}}
  Rectangle{visible:field.type==="hex";width:24;height:24;radius:12;color:backend.accent;anchors.right:input.left;anchors.rightMargin:8;anchors.verticalCenter:input.verticalCenter;MouseArea{anchors.fill:parent;onClicked:picker.open()}}
  ColorDialog{id:picker;title:"Accent colour";selectedColor:backend.accent;onAccepted:backend.send("settings","studioAccent",[String(selectedColor)])}
 }}
 Component{id:swatches;Item{Row{anchors.right:parent.right;anchors.rightMargin:16;anchors.verticalCenter:parent.verticalCenter;spacing:8;Repeater{model:["#7c7a77","#dfdfdc","#b7b8b6","#c9c5c8","#92968d","#59c5a3","#8fb7e3"];delegate:Rectangle{required property string modelData;width:21;height:21;radius:11;color:modelData;border.width:String(backend.accent).toLowerCase()===modelData?2:0;border.color:"#eeeeee";MouseArea{anchors.fill:parent;onClicked:backend.send("settings","studioAccent",[parent.modelData])}}}}}}
 Component{id:action;Item{Text{anchors.right:parent.right;anchors.rightMargin:16;anchors.verticalCenter:parent.verticalCenter;text:field.action==="wallpaper"?"Choose… →":"→";color:"#85857c";font.family:"Inter";font.pixelSize:backend.textSize}MouseArea{anchors.fill:parent;cursorShape:Qt.ArrowCursor;onClicked:backend.action(field.action)}}}
}
