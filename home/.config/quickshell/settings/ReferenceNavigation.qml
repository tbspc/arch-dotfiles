pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import "../components"
import "../services"
import "../theme"

ColumnLayout {
    id: root
    readonly property var design: SettingsDesignService.style
    readonly property bool reference: root.design.appearanceVariant === "settings-studio"
    property var categories: []
    property var sections: []
    property string currentSection: ""
    property string currentCategory: ""
    property bool overview: false
    property string filter: ""
    property bool transientSearch: false
    signal picked(string section)
    signal overviewPicked()
    signal categoryPicked(string category)
    signal filterEdited(string text)

    readonly property color foreground: root.design.textColor || "#1e1a16"
    readonly property color muted: root.design.mutedColor || "#77706b"
    readonly property color selection: Qt.alpha(root.foreground, .07)
    readonly property color accent: root.design.useThemeAccent === false ? (root.design.accentColor || "#bc5a29") : Theme.accentIn(QsWindow.window)
    readonly property string bodyFont: root.design.bodyFont || "Geist"
    readonly property bool animated: !SettingsService.gameMode && root.design.reduceMotion !== true
    readonly property var colours: ["#c76535", "#4c89ba", "#a653a6", "#368aa2", "#4a8bbd", "#678077", "#81756b", "#4c9783", "#72904b"]
    readonly property bool showPresetSections: root.currentCategory === "presets" || root.filter !== ""
    readonly property var navigationRows: {
        const rows = []
        if (!root.filter) {
            rows.push({kind:"overview", id:"overview", label:Tr.t("Overview"), icon:"󰋜", tint:"#718e81"})
            rows.push({kind:"category", id:"presets", label:Tr.t("Presets"), icon:"󰙵", tint:"#6e80b2"})
        }
        for (let i = 0; i < root.categories.length; ++i) {
            const category = root.categories[i]
            if (category.id === "presets" && !root.showPresetSections)
                continue
            const entries = root.sections.filter(section => section.category === category.id)
            if (!entries.length)
                continue
            rows.push({kind:"heading", id:category.id, label:category.label, icon:"", tint:"transparent"})
            for (const section of entries)
                rows.push({kind:"section", id:section.id, label:section.label, icon:section.icon, category:category.id, tint:Theme.sidebarColour(category.id,root.colours[i % root.colours.length])})
        }
        return rows
    }
    readonly property int selectedIndex: {
        if (root.overview)
            return root.navigationRows.findIndex(row => row.kind === (root.currentCategory === "presets" ? "category" : "overview"))
        return root.navigationRows.findIndex(row => row.kind === "section" && row.id === root.currentSection)
    }

    function focusSearch(): void {
        root.transientSearch = true
        Qt.callLater(() => { search.forceActiveFocus(); search.selectAll() })
    }
    function activate(row): void {
        if (row.kind === "overview") root.overviewPicked()
        else if (row.kind === "category" || row.kind === "heading") root.categoryPicked(row.id)
        else root.picked(row.id)
    }
    function step(direction): void {
        let index = root.selectedIndex
        for (let i = 0; i < root.navigationRows.length; ++i) {
            index = (index + direction + root.navigationRows.length) % root.navigationRows.length
            if (root.navigationRows[index].kind !== "heading") {
                root.activate(root.navigationRows[index])
                return
            }
        }
    }
    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        Layout.bottomMargin: 12
        visible: root.design.showSearch !== false || root.transientSearch
        radius: 10
        color: root.selection
        border.width: search.activeFocus ? 1 : 0
        border.color: Qt.alpha(root.accent, .55)
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            Text { text:"󰍉"; font.family:Theme.fontMono; font.pixelSize:15; color:root.muted }
            TextInput {
                id: search
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                font.family: root.bodyFont
                font.pixelSize: 13
                color: root.foreground
                selectionColor: root.accent
                selectedTextColor: "#ffffff"
                selectByMouse: true
                clip: true
                text: root.filter
                onTextEdited: root.filterEdited(text)
                Accessible.name: Tr.t("Search settings")
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !search.text
                    text: Tr.t("Search")
                    color: root.muted
                    font: search.font
                }
                Keys.onEscapePressed: {
                    if (text) { root.filterEdited(""); text = "" }
                }
                Keys.onReturnPressed: {
                    if (root.sections.length) root.picked(root.sections[0].id)
                }
                Keys.onDownPressed: navigation.forceActiveFocus()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        Layout.bottomMargin: 12
        visible: root.design.showProfile === true
        radius: 14
        color: profileMouse.containsMouse ? root.selection : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12
            Avatar {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                source: AccountService.avatar
                initials: AccountService.initials
                ring: "transparent"
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { Layout.fillWidth:true; text:AccountService.name; font.family:root.bodyFont; font.pixelSize:13; font.weight:Font.DemiBold; color:root.foreground; elide:Text.ElideRight }
                Text { Layout.fillWidth:true; text:Tr.t("Profile & preferences"); font.family:root.bodyFont; font.pixelSize:12; color:root.muted; elide:Text.ElideRight }
            }
        }
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Tr.t("Profile")
        Keys.onReturnPressed: root.picked("profile")
        Keys.onSpacePressed: root.picked("profile")
        MouseArea { id:profileMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:root.picked("profile") }
    }

    ListView {
        id: navigation
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.navigationRows
        currentIndex: root.selectedIndex
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 100
        reuseItems: true
        activeFocusOnTab: true
        highlightFollowsCurrentItem: false
        highlight: Rectangle {
            width: navigation.width
            height: 36
            y: navigation.currentItem ? navigation.currentItem.y : 0
            radius: 10
            color: root.selection
            visible: navigation.currentIndex >= 0
            Behavior on y { enabled:root.animated; NumberAnimation { duration:220; easing.type:Easing.OutCubic } }
        }
        Controls.ScrollBar.vertical: Controls.ScrollBar { policy:Controls.ScrollBar.AsNeeded; width:4 }
        Keys.onDownPressed: root.step(1)
        Keys.onUpPressed: root.step(-1)
        Keys.onReturnPressed: {
            if (root.selectedIndex >= 0) root.activate(root.navigationRows[root.selectedIndex])
        }
        onCurrentIndexChanged: {
            if (currentIndex >= 0) Qt.callLater(() => navigation.positionViewAtIndex(navigation.currentIndex, ListView.Contain))
        }
        delegate: Item {
            id: entry
            required property var modelData
            required property int index
            readonly property bool heading: modelData.kind === "heading"
            readonly property bool chosen: index === root.selectedIndex
            width: navigation.width
            height: heading ? 39 : 36
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: modelData.label
            Accessible.selected: chosen
            Keys.onReturnPressed: root.activate(modelData)
            Keys.onSpacePressed: root.activate(modelData)
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: entryMouse.containsMouse && !entry.chosen && !entry.heading ? Qt.alpha(root.foreground, .035) : "transparent"
                border.width: entry.activeFocus ? 1 : 0
                border.color: Qt.alpha(root.accent, .45)
            }
            Text {
                visible: entry.heading
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                text: entry.modelData.label.toUpperCase()
                font.family: root.bodyFont
                font.pixelSize: 11
                font.weight: Font.Medium
                font.letterSpacing: .55
                color: Theme.sidebarTextColour(entry.modelData.id,root.muted)
                elide: Text.ElideRight
            }
            RowLayout {
                visible: !entry.heading
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 8
                    color: Theme.sidebarColour(entry.modelData.category || entry.modelData.id,entry.modelData.tint)
                    Text { anchors.centerIn:parent; text:entry.modelData.icon; font.family:Theme.fontMono; font.pixelSize:15; color:"#ffffff" }
                }
                Text {
                    Layout.fillWidth: true
                    text: entry.modelData.label
                    font.family: root.bodyFont
                    font.pixelSize: 13
                    font.weight: entry.chosen ? Font.Medium : Font.Normal
                    color: Theme.sidebarTextColour(entry.modelData.category || entry.modelData.id,root.foreground)
                    elide: Text.ElideRight
                }
            }
            MouseArea { id:entryMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:root.activate(entry.modelData) }
        }
        Text {
            visible: navigation.count === 0
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            text: Tr.t("No matching settings")
            font.family: root.bodyFont
            font.pixelSize: 12
            color: root.muted
            wrapMode: Text.WordWrap
        }
    }
}
