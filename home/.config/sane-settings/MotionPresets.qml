import QtQuick
Column {
 id:root
 required property var backend
 spacing:12
 Repeater {
  model:[{title:"Shell animations",kind:"shell",presets:root.backend.shellMotionPresets},{title:"Window animations",kind:"windows",presets:root.backend.windowMotionPresets}]
  delegate:Column {
   id:section
   required property var modelData
   width:root.width;spacing:10
   Text{text:section.modelData.title;font.family:"Inter";font.pixelSize:11;color:"#777970"}
   Grid {
    width:parent.width;columns:2;spacing:8
    Repeater {
     model:section.modelData.presets
     delegate:Rectangle {
      required property var modelData
      width:(section.width-8)/2;height:86;radius:12
      color:presetMouse.containsMouse?"#171714":"#0c0c0b"
      border.width:1;border.color:modelData.active?root.backend.accent:"#22221e"
      Rectangle{anchors.right:parent.right;anchors.rightMargin:12;y:13;width:12;height:12;radius:6;color:parent.modelData.active?root.backend.accent:"transparent";border.width:1;border.color:parent.modelData.active?root.backend.accent:"#505148"}
      Text{x:13;y:12;width:parent.width-42;text:parent.modelData.name;font.family:"Inter";font.pixelSize:13;font.weight:Font.Medium;color:"#d0d0c7";elide:Text.ElideRight}
      Text{x:13;y:35;width:parent.width-26;height:38;text:parent.modelData.note||"";font.family:"Inter";font.pixelSize:11;color:"#83857b";wrapMode:Text.Wrap;elide:Text.ElideRight;maximumLineCount:2}
      MouseArea{id:presetMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.ArrowCursor;enabled:root.backend.ready;onClicked:root.backend.send("settings","studioMotion",[section.modelData.kind,parent.modelData.id])}
     }
    }
   }
   Text {visible:section.modelData.presets.length===0;text:"Waiting for animation presets…";font.pixelSize:12;color:"#83857b"}
  }
 }
}
