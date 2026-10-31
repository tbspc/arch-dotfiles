// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   L A U N C H E R   P A N E L                                            │
// │   launcher · apps, calculator, windows, timer, clipboard, emoji          │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import "../../theme"
import "../../services"
import "../../components"

// Application launcher. The first character picks the mode: arithmetic, open
// windows, a countdown, the clipboard history, emoji, or the shell's own
// actions.
ColumnLayout { objectName:"design:LauncherPanel:1";
    id: root

    // The query lives in the service: with `launcherFits` on, the panel's
    // height depends on it, and the island needs that before the panel exists.
    readonly property var appearance:LauncherService.style
    readonly property var results: LauncherService.results
    readonly property var mode: LauncherService.modeFor(LauncherService.query)

    // Emoji are a grid of glyphs; every other mode is a list of rows.
    readonly property bool grid: root.mode.id === "emoji"
    readonly property var view: root.grid ? emojiGrid : resultList

    // Loaded here rather than from the search, which runs inside a binding.
    onModeChanged: {
        if (root.mode.id === "emoji")
            EmojiService.load()
    }

    signal closed()
    // `>` lists panels as rows; picking one hands the island over.
    signal panelRequested(string panel)
    signal settingsRequested()

    spacing: LauncherService.gap

    // Created on open, so this is where the field takes focus; otherwise the
    // window is focusable but nothing inside receives keys.
    //
    // The window list and the application index are refreshed here too. The
    // index is otherwise built once, when `LauncherService` is first touched,
    // and would miss anything installed since. Refreshing on open is cheaper
    // than watching the XDG directories; the new list lands about 50 ms later.
    Component.onCompleted: {
        searchField.forceActiveFocus()
        HyprlandService.loadClients()
        LauncherService.refresh()
        EmojiService.fresh = false
        if (root.mode.id === "emoji")
            EmojiService.load()
    }

    // Cleared on the way out, not on the way in: the island is sized from the
    // query a frame before this panel is built, so clearing it on open would
    // size the island for the last search and then resize it.
    Component.onDestruction: {
        LauncherService.query = ""
        EmojiService.group = ""
    }

    // The list wraps around at both ends. The grid stops at its edges, since
    // a line wrapped to the other end would land in a different column.
    function move(delta: int): void {
        const count = root.results.length
        if (count === 0)
            return
        if (root.grid) {
            const next = emojiGrid.currentIndex + delta
            if (next < 0 || next >= count)
                return
            emojiGrid.currentIndex = next
            emojiGrid.positionViewAtIndex(next, GridView.Contain)
            return
        }
        resultList.currentIndex = root.appearance.wrapNavigation ? (resultList.currentIndex + delta + count) % count : Math.max(0,Math.min(count-1,resultList.currentIndex+delta))
        resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain)
    }

    function kindColour(kind: string): color {
        switch (kind) {
        case "calculation": return Theme.green
        case "action": return Theme.yellow
        case "timer": return Theme.blue
        case "window": return Theme.blue
        default: return Theme.moduleColour("launcher","accent",Theme.accent)
        }
    }

    // Two kinds are not handed to the service. Panels and settings go up to
    // the island. A mode switches the field to that mode and keeps the
    // launcher open. Everything else the service runs, and the launcher closes.
    function run(entry: var): void {
        if (!entry)
            return
        if (entry.kind === "panel") {
            if (entry.panel === "")
                root.settingsRequested()
            else
                root.panelRequested(entry.panel)
            return
        }
        if (entry.kind === "mode") {
            LauncherService.query = entry.sigil
            searchField.forceActiveFocus()
            return
        }
        LauncherService.activate(entry)
        root.closed()
    }

    // Shift or Ctrl with Enter opens a copied image in imv instead of copying
    // it; on any other row it is a plain Enter.
    function confirm(entry: var, modifiers: int): void {
        if (entry && entry.kind === "clip" && entry.file
                && (modifiers & (Qt.ShiftModifier | Qt.ControlModifier))) {
            Quickshell.execDetached(["imv", entry.file])
            root.closed()
            return
        }
        root.run(entry)
    }

    // Only clipboard entries can be forgotten: they are recorded without being
    // chosen, so a mistake needs a way out. The panel stays open, since
    // deleting usually means deleting several.
    function forgetSelected(): void {
        if (root.mode.id !== "clipboard")
            return
        const entry = root.results[root.view.currentIndex]
        if (entry)
            ClipboardService.forget(entry.id)
    }

    // ── FIELD ───────────────────────────────────────────────────────────────
    //
    // Text on the panel's own black with a rule underneath, not a bordered
    // box: the field always has focus, so a focus ring would never turn off.
    RowLayout { objectName:"design:LauncherPanel:2";
        Layout.fillWidth: true
        Layout.preferredHeight: LauncherService.fieldHeight
        spacing: LauncherService.gap

        Item {objectName:"design:LauncherPanel:3";
            visible:root.appearance.showSearchIcon
            Layout.preferredWidth:root.appearance.searchIconSize
            Layout.preferredHeight:root.appearance.searchIconSize
            Layout.alignment:Qt.AlignVCenter
            SearchMagnifier {anchors.fill:parent;visible:root.appearance.searchIconStyle==="outline"&&root.mode.id==="apps";ink:root.appearance.mutedColor||Theme.moduleColour("launcher","muted",Theme.textMuted)}
            Text {anchors.centerIn:parent;visible:root.appearance.searchIconStyle!=="outline"||root.mode.id!=="apps";text:root.mode.icon;font.family:Theme.fontMono;font.pixelSize:root.appearance.searchIconSize;color:Theme.moduleColour("launcher","accent",Theme.accent)}
        }

        TextInput { objectName:"design:LauncherPanel:4";
            id: searchField

            Layout.fillWidth: true
            text: LauncherService.query
            font.family:root.appearance.fontFamily?Theme.fontOf(root.appearance.fontFamily):Theme.fontFamily
            font.pixelSize: root.appearance.searchSize
            color:root.appearance.foregroundColor||Theme.moduleColour("launcher","foreground",Theme.text)
            clip: true
            selectByMouse: true
            selectionColor: Theme.moduleColour("launcher","accent",Theme.accent)
            selectedTextColor: Theme.accentText

            onTextEdited: LauncherService.query = text
            Keys.onReturnPressed: event => root.confirm(root.results[root.view.currentIndex], event.modifiers)
            Keys.onEnterPressed: event => root.confirm(root.results[root.view.currentIndex], event.modifiers)
            Keys.onUpPressed: root.move(root.grid ? -LauncherService.emojiColumns : -1)
            Keys.onDownPressed: root.move(root.grid ? LauncherService.emojiColumns : 1)
            // In the grid the arrows move along a line; the field is a search
            // term, rarely edited in the middle.
            Keys.onLeftPressed: event => {
                event.accepted = root.grid
                if (root.grid)
                    root.move(-1)
            }
            Keys.onRightPressed: event => {
                event.accepted = root.grid
                if (root.grid)
                    root.move(1)
            }
            // Tab steps through the emoji groups; elsewhere it does nothing.
            Keys.onTabPressed: {
                if (root.mode.id === "emoji")
                    EmojiService.stepGroup(1)
            }
            Keys.onBacktabPressed: {
                if (root.mode.id === "emoji")
                    EmojiService.stepGroup(-1)
            }
            // Shift+Delete: plain Delete edits the text, and this cannot be
            // undone.
            Keys.onDeletePressed: event => {
                if (event.modifiers & Qt.ShiftModifier) {
                    root.forgetSelected()
                    event.accepted = true
                } else {
                    event.accepted = false
                }
            }
            // Escape is handled by the island for every panel.

            // The query can be set from outside (a key that opens the launcher
            // in a mode). Typing breaks the `text` binding, so it is resynced
            // here, or the field would show a stale query.
            Connections {
                target: LauncherService

                function onQueryChanged(): void {
                    if (searchField.text !== LauncherService.query)
                        searchField.text = LauncherService.query
                }
            }

            // Only while the field is empty; it would draw over a typed sigil.
            Text { objectName:"design:LauncherPanel:5";
                anchors.verticalCenter: parent.verticalCenter
                text: root.appearance.placeholder
                visible: searchField.text === ""
                color:root.appearance.mutedColor||Theme.moduleColour("launcher","muted",Theme.textMuted)
                font: searchField.font
            }
        }

        // The skin tone every emoji that takes one is shown and copied in.
        // Its mark is the tone itself, on a raised hand; a click steps it.
        Text { objectName:"design:LauncherPanel:6";
            visible: root.mode.id === "emoji"
            text: EmojiService.toneMarks[EmojiService.tone]
            font.family: Theme.fontFamily
            font.pixelSize: 18

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: EmojiService.stepTone()
            }
        }
    }

    // ── GROUPS ──────────────────────────────────────────────────────────────
    //
    // The emoji mode's nine groups and the recent picks, each marked by an
    // emoji and nothing else. Tab steps through them.
    RowLayout { objectName:"design:LauncherPanel:7";
        Layout.fillWidth: true
        Layout.preferredHeight: LauncherService.stripHeight
        visible: LauncherService.showsStrip
        spacing: 2

        Repeater {
            model: EmojiService.groups

            delegate: Rectangle {
                id: chip

                required property var modelData
                readonly property bool chosen: EmojiService.group === chip.modelData.id

                Layout.preferredWidth: LauncherService.stripHeight + 2
                Layout.preferredHeight: LauncherService.stripHeight
                radius: Theme.radiusSmall
                color: chip.chosen || chipMouse.containsMouse
                    ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text { objectName:"design:LauncherPanel:8";
                    anchors.centerIn: parent
                    text: chip.modelData.mark
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    opacity: chip.chosen ? 1 : 0.6
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        EmojiService.group = chip.modelData.id
                        searchField.forceActiveFocus()
                    }
                }
            }
        }

        Item { objectName:"design:LauncherPanel:9"; Layout.fillWidth: true }
    }

    Rectangle { objectName:"design:LauncherPanel:10";
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        visible:root.appearance.showDivider
        color: Theme.borderIn(QsWindow.window)
    }

    // Explicit empty state. In a sigil mode, usually only the sigil has been
    // typed so far.
    Text { objectName:"design:LauncherPanel:11";
        Layout.fillWidth: true
        visible: root.results.length === 0 && LauncherService.query !== ""
        text: root.mode.empty
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.moduleColour("launcher","muted",Theme.textMuted)
    }

    // ── EMOJI ───────────────────────────────────────────────────────────────
    //
    // The glyphs alone, as many to a line as fit; the name is only searched.
    GridView { objectName:"design:LauncherPanel:12";
        id: emojiGrid

        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.grid
        clip: true
        cellWidth: LauncherService.emojiCell
        cellHeight: LauncherService.emojiCell
        model: ScriptModel {
            values: root.grid ? root.results : []

            onValuesChanged: {
                emojiGrid.currentIndex = 0
                emojiGrid.positionViewAtBeginning()
            }
        }
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: 0

        delegate: Rectangle {
            id: cell

            required property var modelData
            required property int index

            readonly property bool selected: GridView.view.currentIndex === cell.index

            width: LauncherService.emojiCell
            height: LauncherService.emojiCell
            radius: Theme.radiusSmall
            color: cell.selected ? Theme.surfaceHoverIn(QsWindow.window) : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            Text { objectName:"design:LauncherPanel:13";
                anchors.centerIn: parent
                text: cell.modelData.glyph ?? ""
                font.family: Theme.fontFamily
                font.pixelSize:root.appearance.emojiSize
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: cell.GridView.view.currentIndex = cell.index
                onClicked: root.run(cell.modelData)
            }
        }
    }

    ListView { objectName:"design:LauncherPanel:14";
        id: resultList

        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.grid
        clip: true
        spacing: LauncherService.rowSpacing
        model: ScriptModel {
            values: root.grid ? [] : root.results

            // Back to the top once the rows have landed, not when the list
            // changes: a row inserted above the selection would shift it.
            // Something is always selected, so Enter always runs a result.
            onValuesChanged: {
                resultList.currentIndex = 0
                resultList.positionViewAtBeginning()
            }
        }
        boundsBehavior: Flickable.StopAtBounds
        // One shared card glides through the list for pointer and keyboard
        // selection. Its coordinates are in the list's scrolling content.
        currentIndex: 0
        highlightFollowsCurrentItem: false
        highlight:LauncherSelection{
            width:resultList.width;height:LauncherService.rowHeight
            y:resultList.currentItem?resultList.currentItem.y:0
            appearance:root.appearance
            visible:resultList.currentItem!==null
            Behavior on y{NumberAnimation{duration:root.appearance.selectionMotion==="slide"?root.appearance.motionDuration:0;easing.type:Easing.OutCubic}}
        }

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index

            // Pointer and keyboard share one selection, so Enter always runs
            // what is lit.
            readonly property bool selected: ListView.view.currentIndex === row.index

            width: ListView.view.width
            height: LauncherService.rowHeight
            radius: Theme.radiusSmall
            color:root.appearance.selectionMotion==="fade"&&row.selected?Qt.alpha(Theme.moduleColour("launcher","accent",Theme.accent),0.06):"transparent"
            Behavior on color{ColorAnimation{duration:root.appearance.motionDuration}}

            LauncherEntryContent{entry:row.modelData;selected:row.selected;tint:root.kindColour(row.modelData.kind)}

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // On movement, not hover: a row appearing under a resting
                // pointer would otherwise steal the selection on open.
                onPositionChanged:if(root.appearance.hoverSelect)row.ListView.view.currentIndex = row.index
                onClicked: mouse => root.confirm(row.modelData, mouse.modifiers)
            }
        }
    }
}
