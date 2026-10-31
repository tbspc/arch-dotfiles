import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../theme"

// The same geometry, Carousel and category transitions as BarPresetPanel.
Item {
    id:root
    required property var categories
    required property var catalogue
    property int categoryIndex:0
    property int currentIndex:0
    property string moduleId:"notes"
    property int stripRevision:0
    property var applied:()=>false
    signal selected(int index)
    signal activated(var preset)
    signal turn(int delta)
    readonly property var activeStrip:{const revision=stripRevision;return pages.itemAt(categoryIndex)?.strip||null}
    function sync():void {
        const strip=root.activeStrip
        if(!strip)return
        strip.goTo(root.currentIndex)
    }
    onCurrentIndexChanged:sync()
    onCategoryIndexChanged:Qt.callLater(root.sync)
    function step(delta:int):void {
        const strip=root.activeStrip
        if(strip?.count)strip.goTo((strip.current+delta+strip.count)%strip.count)
    }
    ColumnLayout {
        anchors.fill:parent;spacing:12
        Item {
            id:viewport
            Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:Math.ceil(100*1.25)+8;clip:true
            Repeater {
                id:pages
                model:root.categories
                onItemAdded:{root.stripRevision++;Qt.callLater(root.sync)}
                onItemRemoved:root.stripRevision++
                Item {
                    id:page
                    required property var modelData
                    required property int index
                    readonly property var strip:pageLoader.item
                    width:viewport.width;height:viewport.height
                    y:(index-root.categoryIndex)*height
                    opacity:index===root.categoryIndex?1:0
                    Behavior on y { NumberAnimation {duration:Theme.durationMorph;easing.type:Theme.easing} }
                    Behavior on opacity { NumberAnimation {duration:Theme.durationMorph;easing.type:Theme.easing} }
                    Loader {
                        id:pageLoader
                        anchors.fill:parent
                        asynchronous:true
                        active:Math.abs(page.index-root.categoryIndex)<=1
                        onLoaded:{root.stripRevision++;if(page.index===root.categoryIndex)root.sync()}
                        sourceComponent:Carousel {
                            id:carousel
                            model:root.catalogue[page.index]||[]
                            tileWidth:160;tileHeight:100;centreScale:1.25;gap:12;virtualized:true;reach:2.5
                            onModelChanged:Qt.callLater(()=>{if(page.index===root.categoryIndex)root.sync()})
                            onCurrentChanged:if(page.index===root.categoryIndex && current!==root.currentIndex)root.selected(current)
                            onActivated:index=>root.activated(model[index])
                            delegate:CarouselTile {
                                id:tile
                                Rectangle {
                                    anchors.fill:parent;radius:Theme.radiusMedium;color:Theme.surface;clip:true;layer.enabled:true;layer.smooth:true;layer.textureSize:Qt.size(200,125)
                                    PresetVisual {anchors.fill:parent;kind:page.modelData.id;moduleId:tile.modelData.moduleId||root.moduleId;values:tile.modelData.values;animate:page.index===root.categoryIndex && tile.visible}
                                    Rectangle {anchors.fill:parent;radius:parent.radius;color:"transparent";border.width:tile.centred?2:1;border.color:tile.centred?Theme.moduleColour("presets","accent",Theme.accent):Theme.border}
                                    Rectangle {anchors.top:parent.top;anchors.right:parent.right;anchors.margins:6;width:18;height:18;radius:9;color:Theme.moduleColour("presets","accent",Theme.accent);visible:root.applied(tile.modelData)
                                        Text {anchors.centerIn:parent;text:"󰄬";font.family:Theme.fontMono;font.pixelSize:10;color:Theme.accentText}
                                    }
                                    Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:23;color:"#a0000000";radius:Theme.radiusSmall}
                                    Text {anchors.bottom:parent.bottom;anchors.bottomMargin:5;anchors.horizontalCenter:parent.horizontalCenter;width:parent.width-10;text:tile.modelData.name;elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter;font.family:Theme.fontFamily;font.pixelSize:10;color:Theme.moduleColour("presets","foreground",Theme.text)}
                                }
                            }
                        }
                    }
                }
            }
            Text {anchors.centerIn:parent;visible:!(root.catalogue[root.categoryIndex]?.length);text:Tr.t("No matching presets");font.family:Theme.fontFamily;font.pixelSize:13;color:Theme.moduleColour("presets","muted",Theme.textMuted)}
        }
        RowLayout {
            Layout.fillWidth:true;spacing:12
            Text {Layout.fillWidth:true;text:Tr.t(root.categories[root.categoryIndex]?.name||"");font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.moduleColour("presets","muted",Theme.textMuted);elide:Text.ElideRight}
            Text {text:root.activeStrip?.count?`${root.activeStrip.current+1}/${root.activeStrip.count}`:"";font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSmall;color:Theme.moduleColour("presets","muted",Theme.textMuted)}
            Text {text:"󰅃";visible:root.categoryIndex>0;font.family:Theme.fontMono;font.pixelSize:Theme.fontSizeRegular;color:upMouse.containsMouse?Theme.moduleColour("presets","foreground",Theme.text):Theme.moduleColour("presets","muted",Theme.textMuted)
                MouseArea {id:upMouse;anchors.fill:parent;anchors.margins:-6;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.turn(-1)}
            }
            Text {text:"󰅀";visible:root.categoryIndex<root.categories.length-1;font.family:Theme.fontMono;font.pixelSize:Theme.fontSizeRegular;color:downMouse.containsMouse?Theme.moduleColour("presets","foreground",Theme.text):Theme.moduleColour("presets","muted",Theme.textMuted)
                MouseArea {id:downMouse;anchors.fill:parent;anchors.margins:-6;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.turn(1)}
            }
        }
    }
}
