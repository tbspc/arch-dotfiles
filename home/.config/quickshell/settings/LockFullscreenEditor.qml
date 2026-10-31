import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

// A presentation editor, separate from the secure session lock surface.
PanelWindow {
    id: root
    property bool shown: false
    property bool showPanels: true
    property string initialMode: "idle"
    property string initialPart: "clock"
    property var initialSettings: null
    signal finished(string mode, string selected)

    function open(output: var, mode: string, selected: string): void {
        if (output) root.screen = output
        root.initialSettings = SettingsService.snapshot()
        root.initialMode = mode || "idle"
        root.initialPart = selected || "clock"
        root.showPanels = true
        root.shown = true
    }
    function close(): void {
        const mode = content.item ? content.item.mode : root.initialMode
        const selected = content.item ? content.item.selected : root.initialPart
        root.shown = false
        root.finished(mode, selected)
    }
    function undo(): void {
        if (!root.initialSettings) return
        for (const key of SettingsService.profileKeys)
            if (key.startsWith("lock") && !key.startsWith("lockMusic"))
                SettingsService.set(key, root.initialSettings[key])
    }

    visible: root.shown
    color: Theme.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "impasto-lock-editor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.shown
        onActivated: root.close()
    }
    Connections {
        target: LockService
        function onLockedChanged(): void { if (LockService.locked && root.shown) root.close() }
    }

    Loader {
        id: content
        anchors.fill: parent
        active: root.shown
        sourceComponent: FocusScope {
            id: stage
            readonly property string mode: preview.mode
            readonly property string selected: preview.selected
            focus: true
            Component.onCompleted: Qt.callLater(() => stage.forceActiveFocus())

            LockDesignPreview {
                id: preview
                anchors.fill: parent
                referenceWidth: Math.max(1, root.width)
                referenceHeight: Math.max(1, root.height)
                radius: 0
                showGuides: root.showPanels
                Component.onCompleted: {
                    preview.mode = root.initialMode
                    preview.selected = root.initialPart
                }
            }

            Rectangle {
                id: toolbar
                visible: root.showPanels
                x: 12; y: 12
                width: parent.width - 24
                height: 40
                radius: Theme.radiusMedium
                color: Qt.alpha(Theme.background, 0.96)
                border.color: Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 6
                    spacing: 10
                    Text {
                        text: Tr.t("Lock screen editor")
                        font.family: Theme.fontIn(QsWindow.window)
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.textIn(QsWindow.window)
                    }
                    Text {
                        visible: toolbar.width > 1200
                        text: Tr.t("Drag the clock or profile · changes save automatically")
                        font.family: Theme.fontIn(QsWindow.window)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.mutedIn(QsWindow.window)
                    }
                    Item { Layout.fillWidth: true }
                    SegmentedControl {
                        options: [
                            {id: "idle", label: Tr.t("Idle")}, {id: "password", label: Tr.t("Password")},
                            {id: "error", label: Tr.t("Wrong password")}, {id: "caps", label: Tr.t("Caps Lock")}
                        ]
                        current: preview.mode
                        onSelected: id => preview.mode = id
                    }
                    PillButton { text: Tr.t("Hide panels"); onClicked: root.showPanels = false }
                    PillButton { text: Tr.t("Undo"); onClicked: root.undo() }
                    PillButton {
                        objectName: "lock-editor-done"
                        text: Tr.t("Done")
                        active: true
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                id: inspector
                visible: root.showPanels
                anchors.top: toolbar.bottom
                anchors.topMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                width: Math.min(446, parent.width * 0.43)
                radius: Theme.radiusMedium
                color: Qt.alpha(Theme.background, 0.96)
                border.color: Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                Flickable {
                    id: scroll
                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: controls.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: controls
                        width: scroll.width
                        spacing: 14
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: Tr.t("Design settings")
                                font.family: Theme.fontIn(QsWindow.window)
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.DemiBold
                                color: Theme.textIn(QsWindow.window)
                            }
                            Text {
                                text: LockStyleService.synced ? Tr.t("Saved") : Tr.t("Saving…")
                                color: LockStyleService.error ? Theme.indicatorBad : Theme.accentIn(QsWindow.window)
                                font.family: Theme.fontIn(QsWindow.window)
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                        SegmentedControl {
                            options: [
                                {id: "clock", label: Tr.t("Clock")}, {id: "profile", label: Tr.t("Profile")},
                                {id: "field", label: Tr.t("Pill")}, {id: "background", label: Tr.t("Background")}
                            ]
                            current: preview.selected
                            onSelected: id => preview.selected = id
                        }
                        LockDesignControls {
                            Layout.fillWidth: true
                            selected: preview.selected
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Tr.t("Changes also apply to the boot login screen. Press Esc or Done to return to Impasto settings.")
                            wrapMode: Text.WordWrap
                            font.family: Theme.fontIn(QsWindow.window)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.mutedIn(QsWindow.window)
                        }
                    }
                }
            }
            PillButton {
                objectName: "lock-editor-show-panels"
                visible: !root.showPanels
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 20
                text: Tr.t("Show editor · Esc to close")
                onClicked: root.showPanels = true
            }
        }
    }
}
