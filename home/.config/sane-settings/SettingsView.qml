import QtQuick
import QtQuick.Controls
import "Data.js" as Data

FocusScope {
    id:root
    implicitWidth:782
    implicitHeight:528
    property string selectedId:"appearance"
    property string query:""
    property var trail:["appearance"]
    property int trailIndex:0
    readonly property var categories:Data.pages
    property var backend
    readonly property var filtered:categories.filter(entry=>entry.name.toLowerCase().includes(query.trim().toLowerCase()))
    readonly property var selected:categories.find(entry=>entry.id===selectedId)||categories[3]
    readonly property int sidebarWidth:212
    function choose(id:string):void {
        if(!categories.some(entry=>entry.id===id)||selectedId===id)return
        trail=trail.slice(0,trailIndex+1).concat([id]);trailIndex=trail.length-1;pageScroll.contentY=0
        selectedId=id;headerFade.restart()
    }
    function back():void {if(trailIndex>0){trailIndex--;selectedId=trail[trailIndex];headerFade.restart()}}
    function forward():void {if(trailIndex<trail.length-1){trailIndex++;selectedId=trail[trailIndex];headerFade.restart()}}
    function step(delta:int):void {
        if(!filtered.length)return
        const index=filtered.findIndex(entry=>entry.id===selectedId)
        choose(filtered[(index+delta+filtered.length)%filtered.length].id)
    }
    function search():void {searchField.forceActiveFocus();searchField.selectAll()}
    Keys.onPressed:event=>{
        if(event.modifiers&Qt.AltModifier&&event.key===Qt.Key_Left){back();event.accepted=true}
        else if(event.modifiers&Qt.AltModifier&&event.key===Qt.Key_Right){forward();event.accepted=true}
        else if(event.key===Qt.Key_Up){step(-1);event.accepted=true}
        else if(event.key===Qt.Key_Down){step(1);event.accepted=true}
        else if(event.key===Qt.Key_Escape&&query){searchField.clear();root.forceActiveFocus();event.accepted=true}
    }
    Rectangle {anchors.fill:parent;color:"#000000"}
    Rectangle {
        id:searchBox
        x:0;y:6;width:198;height:33;radius:11;color:"#141414"
        Image {x:11;anchors.verticalCenter:parent.verticalCenter;width:14;height:14;source:"icons/search.svg";smooth:true;opacity:.7}
        TextInput {
            id:searchField
            x:32;y:(parent.height-height)/2;width:parent.width-x-23
            font.family:"Inter";font.pixelSize:root.backend.textSize;color:"#d0d0cd";selectionColor:"#414141";selectedTextColor:"#ffffff"
            clip:true;selectByMouse:true;onTextChanged:root.query=text
            Keys.onUpPressed:event=>{root.step(-1);event.accepted=true}
            Keys.onDownPressed:event=>{root.step(1);event.accepted=true}
            Text {anchors.fill:parent;visible:!searchField.text&&!searchField.preeditText;text:"Search Settings";font:searchField.font;color:"#777875"}
        }
        Image {anchors.right:parent.right;anchors.rightMargin:7;anchors.verticalCenter:parent.verticalCenter;width:12;height:12;source:"icons/close.svg";visible:root.query!=="";MouseArea {anchors.fill:parent;anchors.margins:-4;onClicked:searchField.clear()}}
    }
    Flickable {
        id:sidebar
        x:0;y:50;width:208;height:parent.height-y-6
        contentHeight:entries.height;clip:true;boundsBehavior:Flickable.StopAtBounds
        Column {
            id:entries;width:198;spacing:2
            Repeater {
                model:root.filtered
                delegate:Rectangle {
                    id:row
                    required property var modelData
                    readonly property bool selected:root.selectedId===modelData.id
                    width:198;height:41;radius:12
                    color:selected?"#202020":rowMouse.containsMouse?"#101010":"transparent"
                    Rectangle {
                        x:7;anchors.verticalCenter:parent.verticalCenter;width:30;height:30;radius:15
                        color:row.selected?root.backend.accent:"#252724"
                        Image {anchors.centerIn:parent;width:18;height:18;source:"icons/"+row.modelData.icon+(row.selected?"-dark":"")+".svg";smooth:true}
                    }
                    Text {x:44;anchors.verticalCenter:parent.verticalCenter;width:146;text:row.modelData.name;font.family:"Inter";font.pixelSize:root.backend.textSize;color:row.selected?"#dededb":"#cececa";elide:Text.ElideRight}
                    MouseArea {id:rowMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.ArrowCursor;onClicked:{root.choose(row.modelData.id);root.forceActiveFocus()}}
                }
            }
        }
    }
    Row {
        x:root.sidebarWidth+12;y:6;spacing:5
        Repeater {
            model:[{icon:"back",available:root.trailIndex>0},{icon:"forward",available:root.trailIndex<root.trail.length-1}]
            delegate:Rectangle {
                required property var modelData
                required property int index
                width:32;height:27;radius:12;color:navMouse.containsMouse&&modelData.available?"#202020":"#121212"
                Image {anchors.centerIn:parent;width:16;height:16;source:"icons/"+modelData.icon+".svg";opacity:parent.modelData.available?1:.45}
                MouseArea {id:navMouse;anchors.fill:parent;hoverEnabled:true;enabled:parent.modelData.available;onClicked:index===0?root.back():root.forward()}
            }
        }
    }
    Flickable {
        id:pageScroll
        x:root.sidebarWidth+20;y:42;width:Math.max(200,parent.width-x-10);height:parent.height-y-12
        contentHeight:content.height;clip:true;boundsBehavior:Flickable.StopAtBounds
        ScrollBar.vertical:ScrollBar { policy:ScrollBar.AsNeeded }
        Column {
            id:content;width:pageScroll.width-6;spacing:12
            Rectangle {
                width:parent.width;height:156;radius:18;color:"#090909"
                Item {
                    id:heading;anchors.fill:parent
                    Rectangle {anchors.horizontalCenter:parent.horizontalCenter;y:23;width:58;height:58;radius:29;color:"#20211f";Image {anchors.centerIn:parent;width:32;height:32;source:"icons/"+root.selected.icon+".svg";smooth:true}}
                    Text {anchors.horizontalCenter:parent.horizontalCenter;y:87;text:root.selected.name;font.family:"Inter";font.pixelSize:20;font.weight:Font.Medium;color:"#cbcbc6"}
                    Text {x:12;width:parent.width-24;y:118;text:root.selected.description;font.family:"Inter";font.pixelSize:root.backend.textSize;color:"#7c7d78";horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap}
                }
            }
            Text {visible:backend.error!=="";text:backend.error;width:parent.width;wrapMode:Text.Wrap;font.pixelSize:12;color:"#dab28a"}
            MotionPresets {width:content.width;visible:root.selectedId==="motion";height:visible?implicitHeight:0;backend:root.backend}
            Repeater {
                model:root.selected.groups
                delegate:Column {
                    required property var modelData
                    width:content.width;spacing:10
                    Text {visible:parent.modelData.title!=="";text:parent.modelData.title;color:"#777970";font.family:"Inter";font.pixelSize:11;height:visible?16:0}
                    Rectangle {
                        width:parent.width;height:rows.height;radius:16;color:"#090909"
                        Column {
                            id:rows;width:parent.width
                            Repeater {model:modelData.rows;delegate:ControlRow{required property var modelData;field:modelData;backend:root.backend;enabled:root.backend.ready}}
                        }
                    }
                }
            }
            Item{width:1;height:8}
        }
    }
    NumberAnimation {id:headerFade;target:heading;property:"opacity";from:.65;to:1;duration:120;easing.type:Easing.OutCubic}
    Shortcut {sequence:"Ctrl+K";onActivated:root.search()}
    Shortcut {sequence:"Ctrl+F";onActivated:root.search()}
    Component.onCompleted:root.forceActiveFocus()
}
