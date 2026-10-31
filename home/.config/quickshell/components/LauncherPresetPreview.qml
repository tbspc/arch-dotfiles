import QtQuick
import Quickshell
import "../theme"
import "../services"
Rectangle {
    id:root
    property var values:({})
    readonly property var design:Object.assign({},LauncherPresetService.defaults,values.launcherStyle||{})
    property bool large:false
    implicitHeight:large?320:220
    color:Theme.surface
    radius:Theme.radiusMedium
    clip:true
    readonly property real rowHeight:LauncherPresetService.rowHeightFor(root.design)
    Item{
        id:scene
        width:root.design.width
        height:root.design.fieldHeight+2*root.design.gap+(root.design.showDivider?1:0)+3*root.rowHeight+2*root.design.rowSpacing+2*root.design.padding
        scale:Math.min((root.width-20)/width,(root.height-20)/height)
        x:(root.width-width*scale)/2;y:(root.height-height*scale)/2
        transformOrigin:Item.TopLeft
        Rectangle{anchors.fill:parent;radius:root.design.cornerRadius;color:root.design.surfaceTone==="grey"?"#24262b":root.design.surfaceTone==="black"?"#000000":Theme.islandGround;border.width:1;border.color:Theme.border}
        Item{
            x:root.design.padding;y:root.design.padding;width:scene.width-2*x;height:scene.height-2*y
            SearchMagnifier{visible:root.design.showSearchIcon&&root.design.searchIconStyle==="outline";x:0;y:(root.design.fieldHeight-height)/2;width:root.design.searchIconSize;height:width;ink:root.design.mutedColor||Theme.textMuted}
            Text{visible:root.design.showSearchIcon&&root.design.searchIconStyle!=="outline";x:0;y:(root.design.fieldHeight-height)/2;text:"󰍉";font.family:Theme.fontMono;font.pixelSize:root.design.searchIconSize;color:Theme.accentIn(QsWindow.window)}
            Text{x:root.design.showSearchIcon?root.design.searchIconSize+root.design.gap:0;y:(root.design.fieldHeight-height)/2;text:root.design.placeholder||"Search…";font.family:root.design.fontFamily?Theme.fontOf(root.design.fontFamily):Theme.fontFamily;font.pixelSize:root.design.searchSize;color:root.design.mutedColor||Theme.textMuted}
            Rectangle{visible:root.design.showDivider;y:root.design.fieldHeight+root.design.gap;width:parent.width;height:1;color:Theme.border}
            Repeater{
                model:[{kind:"app",name:"Terminal",subtitle:"Command line",icon:"utilities-terminal"},{kind:"app",name:"Files",subtitle:"File manager",icon:"org.gnome.Nautilus"},{kind:"app",name:"Browser",subtitle:"Web browser",icon:"brave-browser"}]
                Item{
                    required property var modelData
                    required property int index
                    y:root.design.fieldHeight+2*root.design.gap+(root.design.showDivider?1:0)+index*(root.rowHeight+root.design.rowSpacing)
                    width:parent.width;height:root.rowHeight
                    LauncherSelection{anchors.fill:parent;visible:index===1;appearance:root.design}
                    LauncherEntryContent{preview:true;entry:modelData;selected:index===1;appearance:root.design}
                }
            }
        }
    }
}
