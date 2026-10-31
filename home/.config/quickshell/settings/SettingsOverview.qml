import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import "../components"
import "../services"
import "../theme"

Flickable {
    id: root
    property var categories: []
    property var sections: []
    property string category: ""
    property bool searching: false
    signal picked(string section, string tab)
    signal categoryPicked(string category)
    readonly property bool home: category === "" && !searching
    readonly property var entries: home ? categories.filter(c=>sections.some(s=>s.category===c.id)) : sections.filter(s=>searching || s.category===category)
    clip:true;contentWidth:width;contentHeight:body.implicitHeight;boundsBehavior:Flickable.StopAtBounds
    onCategoryChanged:contentY=0
    onSearchingChanged:contentY=0
    Controls.ScrollBar.vertical:Controls.ScrollBar {}
    ColumnLayout {
        id:body
        width:root.width;spacing:20
        RowLayout {
            Layout.fillWidth:true
            ColumnLayout { Layout.fillWidth:true;spacing:6
                Text { Layout.fillWidth:true;text:root.searching?Tr.t("Search results"):root.home?Tr.t("Overview"):root.categories.find(c=>c.id===root.category)?.label || "";font.family:Theme.fontIn(QsWindow.window);font.pixelSize:30;font.weight:Font.Bold;color:Theme.textIn(QsWindow.window) }
                Text { Layout.fillWidth:true;text:root.home?Tr.t("Everything in one place. Pick a category to get started."):Tr.t("Choose a section to open its settings.");wrapMode:Text.WordWrap;color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13 }
            }
            PillButton { visible:!root.home;text:Tr.t("All categories");onClicked:root.categoryPicked("") }
        }
        GridLayout {
            Layout.fillWidth:true
            columns:width>=720?3:width>=440?2:1
            columnSpacing:12;rowSpacing:12
            Repeater {
                model:root.entries
                Rectangle {
                    id:card
                    required property var modelData
                    readonly property var members:root.home?root.sections.filter(s=>s.category===modelData.id):[]
                    Layout.fillWidth:true;Layout.preferredWidth:1
                    implicitHeight:root.home?116:110;radius:16
                    color:cardHover.hovered?Theme.surfaceHoverIn(QsWindow.window):(SettingsDesignService.style.cardBackground || Theme.surfaceIn(QsWindow.window))
                    border.width:1;border.color:cardHover.hovered || activeFocus ? Qt.alpha(Theme.accentIn(QsWindow.window),.65):Theme.borderIn(QsWindow.window)
                    activeFocusOnTab:true
                    Accessible.role:Accessible.Button;Accessible.name:modelData.label
                    Keys.onReturnPressed:root.home?root.categoryPicked(modelData.id):root.picked(modelData.id,"")
                    Keys.onSpacePressed:root.home?root.categoryPicked(modelData.id):root.picked(modelData.id,"")
                    ColumnLayout {
                        anchors.fill:parent;anchors.margins:16;spacing:8
                        RowLayout { Layout.fillWidth:true;spacing:10
                            Text { text:card.modelData.icon;font.family:Theme.fontMono;font.pixelSize:23;color:Theme.accentIn(QsWindow.window) }
                            Text { Layout.fillWidth:true;text:card.modelData.label;wrapMode:Text.WordWrap;maximumLineCount:2;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:14;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window) }
                            Text { text:"›";font.pixelSize:22;color:Theme.mutedIn(QsWindow.window) }
                        }
                        Text { Layout.fillWidth:true;text:root.home?card.members.map(s=>s.label).join(" · "):card.modelData.blurb;wrapMode:Text.WordWrap;maximumLineCount:2;elide:Text.ElideRight;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window) }
                        Item { Layout.fillHeight:true }
                    }
                    HoverHandler { id:cardHover;cursorShape:Qt.PointingHandCursor }
                    TapHandler { onTapped:root.home?root.categoryPicked(card.modelData.id):root.picked(card.modelData.id,"") }
                }
            }
        }
        Text { visible:root.entries.length===0;text:Tr.t("No matching settings. Try another search.");color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:14 }
    }
}
