import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import "../services"
import "../theme"
ColumnLayout {
    id: root
    property var categories: []
    property var sections: []
    property string selected: ""
    property string currentSection: ""
    property string currentTab: ""
    signal categoryPicked(string category)
    signal sectionPicked(string section, string tab)
    spacing: 12
    RowLayout {
        Layout.fillWidth:true;Layout.margins:8
        ArchMark { size:34 }
        ColumnLayout {
            spacing:2
            Text { text:"Hyprland";color:Theme.textIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:23;font.weight:Font.DemiBold }
            Text { text:Tr.t("Make it yours");color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12 }
        }
    }
    Rectangle { Layout.fillWidth:true;Layout.preferredHeight:1;Layout.topMargin:8;Layout.bottomMargin:8;color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border) }
    PillButton { Layout.fillWidth:true;text:Tr.t("All settings");active:root.selected === "";onClicked:root.categoryPicked("") }
    Controls.ScrollView {
        Layout.fillWidth:true;Layout.fillHeight:true
        clip:true
        contentWidth:availableWidth
        Controls.ScrollBar.horizontal.policy:Controls.ScrollBar.AlwaysOff
        ColumnLayout {
            width:parent.width
            spacing:6
            Repeater {
                model:root.categories
                ColumnLayout {
                    id:group
                    required property var modelData
                    Layout.fillWidth:true;spacing:3
                    Rectangle {
                        id:tile
                        readonly property bool chosen:root.selected === group.modelData.id
                        Layout.fillWidth:true;implicitHeight:74;radius:14
                        color:chosen?Qt.alpha(Theme.accentIn(QsWindow.window),.13):mouse.containsMouse?Qt.alpha(Theme.textIn(QsWindow.window),.04):"transparent"
                        border.width:1;border.color:chosen?Qt.alpha(Theme.accentIn(QsWindow.window),.5):"transparent"
                        RowLayout {
                            anchors.fill:parent;anchors.margins:12;spacing:12
                            Text { text:group.modelData.icon;color:tile.chosen?Theme.accentIn(QsWindow.window):Theme.mutedIn(QsWindow.window);font.family:Theme.fontMono;font.pixelSize:20 }
                            ColumnLayout {
                                Layout.fillWidth:true;spacing:4
                                Text { Layout.fillWidth:true;text:group.modelData.label;wrapMode:Text.WordWrap;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:14;font.weight:Font.DemiBold;color:tile.chosen?Theme.accentIn(QsWindow.window):Theme.textIn(QsWindow.window) }
                                Text { Layout.fillWidth:true;text:group.modelData.description;wrapMode:Text.WordWrap;maximumLineCount:2;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window) }
                            }
                        }
                        MouseArea { id:mouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.categoryPicked(group.modelData.id) }
                    }
                    Repeater {
                        model:root.selected === group.modelData.id ? root.sections.filter(e=>e.category===group.modelData.id) : []
                        ColumnLayout {
                            id:section
                            required property var modelData
                            Layout.fillWidth:true;Layout.leftMargin:14;spacing:2
                            PillButton {
                                Layout.fillWidth:true
                                horizontalPadding:8
                                text:section.modelData.label
                                active:root.currentSection===section.modelData.id
                                onClicked:root.sectionPicked(section.modelData.id,"")
                            }
                            Repeater {
                                model:root.currentSection===section.modelData.id?section.modelData.tabs:[]
                                Rectangle {
                                    id:sub
                                    required property var modelData
                                    readonly property bool chosen:root.currentTab===modelData.id
                                    Layout.fillWidth:true;Layout.leftMargin:12
                                    implicitHeight:Math.max(32,label.implicitHeight+12);radius:8
                                    color:chosen?Qt.alpha(Theme.accentIn(QsWindow.window),.09):subMouse.containsMouse?Qt.alpha(Theme.textIn(QsWindow.window),.04):"transparent"
                                    Text { id:label;anchors.left:parent.left;anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;anchors.margins:10;text:sub.modelData.label;wrapMode:Text.WordWrap;color:sub.chosen?Theme.accentIn(QsWindow.window):Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13 }
                                    MouseArea { id:subMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.sectionPicked(section.modelData.id,sub.modelData.id) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
