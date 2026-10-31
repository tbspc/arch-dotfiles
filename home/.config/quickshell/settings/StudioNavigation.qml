import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import "../components"
import "../services"
import "../theme"

ColumnLayout {
    id: root
    readonly property var design:SettingsDesignService.style
    readonly property bool forma:SettingsDesignService.forma
    property var categories: []
    property var sections: []
    property string currentSection: ""
    property string currentCategory: ""
    property bool overview: false
    property string filter: ""
    readonly property color accent: Theme.accentIn(QsWindow.window)
    readonly property var colours: ["#60baf4", "#c88de6", "#eeaf74", "#e1c765", "#69bdd1", "#7cbe9e", "#a0acb9", "#8f9dea"]
    signal picked(string section)
    signal overviewPicked()
    signal categoryPicked(string category)
    signal filterEdited(string text)
    property bool transientSearch:false
    function focusSearch():void {root.transientSearch=true;Qt.callLater(()=>{search.forceActiveFocus();search.selectAll()})}
    spacing:root.forma?root.design.sidebarSpacing:12

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        spacing: 12
        ArchMark { size: 28 }
        Text { text:root.forma?root.design.brandName||"Hyprland":"Hyprland"; color: Theme.textIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 20; font.weight: Font.Bold }
    }
    Rectangle {
        visible:root.forma && root.design.showProfile
        Layout.fillWidth:true;implicitHeight:62;radius:10;color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:Theme.borderIn(QsWindow.window)
        RowLayout {anchors.fill:parent;anchors.margins:10;spacing:10
            Avatar {Layout.preferredWidth:28;Layout.preferredHeight:28;source:AccountService.avatar;initials:AccountService.initials;ring:"transparent"}
            ColumnLayout {Layout.fillWidth:true;spacing:3
                Text {Layout.fillWidth:true;text:AccountService.name;elide:Text.ElideRight;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;font.weight:Font.Medium;color:Theme.textIn(QsWindow.window)}
                Text {text:Tr.t("Your desktop");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window)}
            }
        }
        TapHandler {onTapped:root.picked("profile")}
    }
    Rectangle {
        visible:!root.forma||root.design.showSearch||root.transientSearch
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 12
        color: Theme.surfaceIn(QsWindow.window)
        border.width: 1
        border.color: search.activeFocus ? root.accent : Theme.borderIn(QsWindow.window)
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 9
            Text { text: "󰍉"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.mutedIn(QsWindow.window) }
            TextInput {
                id: search
                Layout.fillWidth: true; Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 12
                color: Theme.textIn(QsWindow.window); selectionColor: root.accent; selectByMouse: true; clip: true
                text: root.filter
                onTextEdited: root.filterEdited(text)
                Text { anchors.verticalCenter: parent.verticalCenter; visible: !parent.text; text: Tr.t("Search or jump to…"); color: Theme.mutedIn(QsWindow.window); font: parent.font }
                Keys.onEscapePressed: if (text) { root.filterEdited(""); text = "" }
                Keys.onReturnPressed: if (root.sections.length) root.picked(root.sections[0].id)
            }
            Rectangle {
                implicitWidth: 42; implicitHeight: 20; radius: 5; color: "transparent"; border.width: 1; border.color: Theme.borderIn(QsWindow.window)
                Text { anchors.centerIn: parent; text: "Ctrl K"; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.mutedIn(QsWindow.window) }
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 44; radius: 11
        color: root.overview ? Qt.alpha(root.accent, .10) : homeMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"
        border.width: 1; border.color: root.overview ? Qt.alpha(root.accent, .65) : "transparent"
        RowLayout {
            anchors.fill: parent; anchors.margins: 9; spacing: 12
            Rectangle { width: 28; height: 28; radius: 8; color: Qt.alpha(root.accent, .12)
                Text { anchors.centerIn: parent; text: "󰋜"; color: root.accent; font.family: Theme.fontMono; font.pixelSize: 18 }
            }
            Text { text: Tr.t("Overview"); color: Theme.textIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 13; font.weight: Font.Medium }
            Item { Layout.fillWidth: true }
        }
        activeFocusOnTab: true
        Keys.onReturnPressed: root.overviewPicked()
        Keys.onSpacePressed: root.overviewPicked()
        MouseArea { id: homeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.overviewPicked() }
    }
    Rectangle {
        Layout.fillWidth:true;implicitHeight:42;radius:11
        color:root.currentCategory==="presets"?Qt.alpha(root.accent,.10):presetsMouse.containsMouse?Theme.surfaceHoverIn(QsWindow.window):"transparent"
        RowLayout { anchors.fill:parent;anchors.margins:9;spacing:12
            Rectangle { width:28;height:28;radius:8;color:Qt.alpha(root.accent,.12)
                Text { anchors.centerIn:parent;text:"󰙵";font.family:Theme.fontMono;font.pixelSize:18;color:root.accent }
            }
            Text { Layout.fillWidth:true;text:Tr.t("Presets");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13;color:Theme.textIn(QsWindow.window) }
            Text { text:"›";color:Theme.mutedIn(QsWindow.window);font.pixelSize:19 }
        }
        activeFocusOnTab:true
        Keys.onReturnPressed:root.categoryPicked("presets")
        Keys.onSpacePressed:root.categoryPicked("presets")
        MouseArea { id:presetsMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.categoryPicked("presets") }
    }
    Controls.ScrollView {
        Layout.fillWidth: true; Layout.fillHeight: true
        contentWidth: availableWidth; clip: true
        Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
        ColumnLayout {
            width: parent.width; spacing: 4
            Repeater {
                model: root.categories.filter(c=>c.id!=="presets" || root.currentCategory==="presets" || root.filter!=="")
                ColumnLayout {
                    id: group
                    required property var modelData
                    required property int index
                    readonly property var entries: root.sections.filter(s => s.category === modelData.id)
                    Layout.fillWidth: true
                    visible: entries.length > 0
                    spacing: 4
                    Text {
                        Layout.fillWidth: true; Layout.leftMargin: 10; Layout.topMargin: 10; Layout.bottomMargin: 2
                        visible:!root.forma||root.design.showCategoryLabels;text: group.modelData.label.toUpperCase(); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 10; font.letterSpacing: 1.1; color: Theme.sidebarTextColour(group.modelData.id,Theme.mutedIn(QsWindow.window))
                    }
                    Repeater {
                        model: group.entries
                        Rectangle {
                            id: entry
                            required property var modelData
                            readonly property bool chosen: root.currentSection === modelData.id && !root.overview
                            Layout.fillWidth: true; implicitHeight:root.forma?root.design.navRowHeight:42;radius:root.forma?root.design.navRadius:11
                            color: chosen ? Qt.alpha(root.accent, .10) : entryMouse.containsMouse ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"
                            border.width: 1; border.color: chosen || activeFocus ? Qt.alpha(root.accent, .80) : "transparent"
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.label
                            Keys.onReturnPressed: root.picked(modelData.id)
                            Keys.onSpacePressed: root.picked(modelData.id)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 10; spacing: 12
                                Rectangle {
                                    visible:!root.forma||root.design.sidebarIcons
                                    width:28;height:28;radius:8
                                    readonly property color tone:Theme.sidebarColour(group.modelData.id,entry.chosen ? root.accent : root.forma?Theme.mutedIn(QsWindow.window):root.colours[group.index % root.colours.length])
                                    color:root.forma?"transparent":Qt.alpha(tone,.12)
                                    Text { anchors.centerIn: parent; text: entry.modelData.icon; font.family: Theme.fontMono; font.pixelSize:root.forma?root.design.sidebarIconSize:17;color:parent.tone }
                                }
                                Text { Layout.fillWidth: true; text: entry.modelData.label; elide: Text.ElideRight; font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 13; font.weight: entry.chosen ? Font.DemiBold : Font.Normal; color:Theme.sidebarTextColour(group.modelData.id,Theme.textIn(QsWindow.window)) }
                                Text { text: entry.chosen ? "›" : ""; font.pixelSize: 19; color: root.accent }
                            }
                            MouseArea { id: entryMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.picked(entry.modelData.id) }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; Layout.margins: 12; visible: root.sections.length === 0; text: Tr.t("No matching settings"); color: Theme.mutedIn(QsWindow.window); font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 13; wrapMode: Text.WordWrap }
        }
    }
    Rectangle {
        visible:!root.forma
        Layout.fillWidth: true; implicitHeight: 64; radius: 13; color: Theme.surfaceIn(QsWindow.window); border.width: 1; border.color: Theme.borderIn(QsWindow.window)
        RowLayout {
            anchors.fill: parent; anchors.margins: 11; spacing: 10
            Avatar { Layout.preferredWidth: 36; Layout.preferredHeight: 36; source: AccountService.avatar; initials: AccountService.initials; ring: "transparent" }
            ColumnLayout { Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: AccountService.name; elide: Text.ElideRight; font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.textIn(QsWindow.window) }
                Text { Layout.fillWidth: true; text: AccountService.user; elide: Text.ElideRight; font.family: Theme.fontIn(QsWindow.window); font.pixelSize: 11; color: Theme.mutedIn(QsWindow.window) }
            }
            Text { text: "󰅂"; font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.mutedIn(QsWindow.window) }
        }
        activeFocusOnTab: true
        Keys.onReturnPressed: root.picked("profile")
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.picked("profile") }
    }
}
