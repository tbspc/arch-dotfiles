// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I S L A N D   S E C T I O N                                            │
// │   island · where it sits, the time, what runs beside it, notifications   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import QtQuick.Layouts
import Quickshell

import "../theme"
import "../services"
import "../components"

// The island, its resting clock and indicators, and the notifications that
// take it over. The shell is the notification daemon, so they are the island's.
SettingsSection {
    id: root

    // The visible part; set by `SettingsPanel`.
    property string tab: ""
    WorkspaceColourSettings {visible:root.tab==="workspaces"}
    WorkspaceBrightnessSettings {visible:root.tab==="workspaces"}
    WorkspaceGlowSettings {visible:root.tab==="workspaces";showToggle:false}

    // A live clock, so the format tiles show the real time in the real
    // typeface.
    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Loader {
        Layout.fillWidth: true
        active: root.tab === "presets"
        visible: active
        sourceComponent: IslandPresets {}
    }

    Loader {
        Layout.fillWidth: true
        active: root.tab === "chips"
        visible: active
        sourceComponent: IslandChipsSection {}
    }

    // ── THE ISLAND ──────────────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: root.tab === "island"

        SettingGroup {
            title: Tr.t("The island")
            note: Tr.t("Where the island meets the top edge, and what opens it.")
            hint: Tr.t("A notch cuts the island into the top edge, and the bar's top margin no longer applies to it.")

            SettingTiles {
                label: Tr.t("Position")
                locked: SettingsService.barStyle === "bezel"
                reason: Tr.t("The bezel is always cut into the top edge")
                reading: SettingsService.notched
                    ? Tr.t("Cut into the top edge")
                    : Tr.t("Floating below the top edge")

                PreviewTile {
                    caption: Tr.t("Floating")
                    selected: !SettingsService.islandAttached
                    onPicked: SettingsService.set("islandAttached", false)

                    BarPreview {
                        anchors.centerIn: parent
                        attached: false
                        barStyle: SettingsService.barStyle
                    }
                }

                PreviewTile {
                    caption: "Notch"
                    selected: SettingsService.islandAttached
                    onPicked: SettingsService.set("islandAttached", true)

                    BarPreview {
                        anchors.centerIn: parent
                        attached: true
                        barStyle: SettingsService.barStyle
                    }
                }
            }

            SettingSlider {
                label: Tr.t("Floating top gap")
                visible: !SettingsService.notched
                value: SettingsService.islandFloatingGap
                from: 0
                to: 48
                stepSize: 1
                unit: " px"
                onMoved: value => SettingsService.set("islandFloatingGap", Math.round(value))
            }

            SettingRow {
                label: Tr.t("Open calendar and media")
                locked:SettingsService.barAutoHide
                reason:Tr.t("Auto-hide temporarily uses Click. Your previous choice returns when it is off.")
                reading: SettingsService.islandSummaryMode === "hover"
                    ? Tr.t("Hover over the clock; click the preview for Control Centre")
                    : Tr.t("Click the clock; click the view's background for Control Centre")

                SegmentedControl {
                    options: [
                        { id: "hover", label: Tr.t("Hover") },
                        { id: "click", label: Tr.t("Click") }
                    ]
                    current: SettingsService.islandSummaryMode
                    onSelected: id => SettingsService.set("islandSummaryMode", id)
                }
            }

        }

        SettingGroup {
            visible:SettingsService.islandSummaryMode==="click"
            title:Tr.t("Click-mode hover")
            SettingRow {label:Tr.t("Enlarge bar on hover");reading:Tr.t("Gently grow the resting bar from its centre while the pointer is over it.");ToggleSwitch {checked:SettingsService.barClickHoverEnlarge;onToggled:value=>SettingsService.set("barClickHoverEnlarge",value)}}
        }
        SettingGroup {
            visible:SettingsService.islandSummaryMode==="click"
            title:Tr.t("Hover appearance")
            SettingRow {visible:SettingsService.barClickHoverEnlarge;label:Tr.t("Enlarge background only");reading:Tr.t("Keep the clock, text and icons at their normal sizes.");ToggleSwitch {checked:SettingsService.barHoverEnlargeBackgroundOnly;onToggled:value=>SettingsService.set("barHoverEnlargeBackgroundOnly",value)}}
            SettingSlider {visible:SettingsService.barClickHoverEnlarge;label:Tr.t("Hover enlargement");from:1;to:20;unit:"%";value:SettingsService.barHoverEnlargeAmount;onMoved:value=>SettingsService.set("barHoverEnlargeAmount",Math.round(value*10)/10)}
            SettingSlider {visible:SettingsService.barClickHoverEnlarge;label:Tr.t("Extra hover width");from:0;to:200;unit:" px";value:SettingsService.barHoverExtraWidth;onMoved:value=>SettingsService.set("barHoverExtraWidth",Math.round(value))}
            SettingSlider {visible:SettingsService.barClickHoverEnlarge;label:Tr.t("Extra hover height");from:0;to:80;unit:" px";value:SettingsService.barHoverExtraHeight;onMoved:value=>SettingsService.set("barHoverExtraHeight",Math.round(value))}
            SettingRow {label:Tr.t("Brighten bar on hover");ToggleSwitch {checked:SettingsService.barHoverHighlight;onToggled:value=>SettingsService.set("barHoverHighlight",value)}}
        }
        HoverDesignSettings {}
        HoverLayoutSettings {}
        HoverTimingSettings {}

        // ── CLOCK ───────────────────────────────────────────────────────────

        SettingGroup {
            title: Tr.t("Clock")
            note: Tr.t("Shown on the resting island, and larger in the glance.")
            hint: Tr.t("Seconds make the clock repaint sixty times as often.")

            SettingTiles {
                label: Tr.t("Clock format")

                Repeater {
                    model: SettingsService.clockFormats

                    PreviewTile {
                        id: formatTile

                        required property var modelData

                        caption: Tr.t(formatTile.modelData.label)
                        selected: SettingsService.clockFormat === formatTile.modelData.id
                        onPicked: SettingsService.set("clockFormat", formatTile.modelData.id)

                        Text {
                            anchors.centerIn: parent
                            text: Qt.formatDateTime(clock.date, SettingsService.clockShowsSeconds
                                ? formatTile.modelData.id.replace("mm", "mm:ss")
                                : formatTile.modelData.id)
                            font.family: Theme.fontIn(QsWindow.window)
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.DemiBold
                            color: Theme.textIn(QsWindow.window)
                        }
                    }
                }
            }

            SettingRow {
                label: Tr.t("Show the date")
                reading: SettingsService.clockShowsDate
                    ? Tr.t("Beside the time") : Tr.t("The time alone")

                ToggleSwitch {
                    checked: SettingsService.clockShowsDate
                    onToggled: checked => SettingsService.set("clockShowsDate", checked)
                }
            }

            SettingRow {
                label: Tr.t("Show seconds")

                ToggleSwitch {
                    checked: SettingsService.clockShowsSeconds
                    onToggled: checked => SettingsService.set("clockShowsSeconds", checked)
                }
            }
        }

        // ── BESIDE THE TIME ─────────────────────────────────────────────────
        //
        // Modules shown either side of the time while they run.

        SettingGroup {
            title: Tr.t("Beside the time")
            note: Tr.t("What is running sits either side of the time, two at most.")
            hint: Tr.t("A recording is always there and comes first; click its dot to stop it. Then the microphone, camera or screen in use, a countdown and media, which still work from their chips on the bar when kept off the island. The workspace comes last, for a bar without the strip; click it for the overview.")

            Repeater {
                model: SettingsService.besideChoices

                SettingRow {
                    id: besideRow

                    required property string modelData

                    readonly property bool privacy: besideRow.modelData === "privacy"
                    readonly property bool workspace: besideRow.modelData === "workspace"
                    readonly property bool machine: besideRow.modelData === "machine"
                    readonly property bool on: SettingsService.beside(besideRow.modelData)

                    label: besideRow.privacy ? Tr.t("Privacy")
                        : besideRow.workspace ? Tr.t("Workspace")
                        : besideRow.machine ? Tr.t("Virtual machines")
                        : Tr.t(ModuleService.entry(besideRow.modelData).name)
                    reading: besideRow.privacy
                        ? (besideRow.on ? Tr.t("What uses the microphone, camera or screen") : Tr.t("Not shown"))
                        : besideRow.workspace
                            ? (besideRow.on ? Tr.t("The one you are on") : Tr.t("Not shown"))
                        : besideRow.machine
                            ? (besideRow.on ? Tr.t("On the island while one runs") : Tr.t("Not shown"))
                        : besideRow.on
                            ? Tr.t("On the island while it runs") : Tr.t("Only where its chip is put")

                    ToggleSwitch {
                        checked: SettingsService.beside(besideRow.modelData)
                        onToggled: checked => SettingsService.setBeside(besideRow.modelData, checked)
                    }
                }
            }
        }

    }

    // ── CLOCK AND INDICATORS ────────────────────────────────────────────────

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.spacing
        visible: ["indicators","workspaces","network","bluetooth","volume","battery"].includes(root.tab)

        SettingGroup {
            visible:root.tab === "indicators"
            title: Tr.t("Clock and pill")
            note: Tr.t("Size and spacing for the resting island.")
            hint: Tr.t("Left and right padding each add to the pill width and inset the side groups. Set a padding slider to zero to remove that extra width. Each indicator's position chooses its side of the clock, while its offset nudges it from that side. Positive offsets move toward the right of the screen.")

            SettingRow {
                label: Tr.t("Pill layout")
                reading: SettingsService.islandLayout === "balanced"
                    ? Tr.t("Clock centered, indicators at the sides")
                    : Tr.t("Grouped together")
                SegmentedControl {
                    options: [
                        { id: "compact", label: Tr.t("Compact") },
                        { id: "balanced", label: Tr.t("Centered") }
                    ]
                    current: SettingsService.islandLayout
                    onSelected: id => SettingsService.set("islandLayout", id)
                }
            }

            SettingSlider {
                label: Tr.t("Pill width")
                value: SettingsService.islandPillWidth
                from: 80
                to: 520
                unit: " px"
                onMoved: value => SettingsService.set("islandPillWidth", Math.round(value))
            }
            SettingSlider {
                label: Tr.t("Left padding")
                value: SettingsService.islandPaddingLeft
                from: 0
                to: 64
                unit: " px"
                onMoved: value => SettingsService.set("islandPaddingLeft", Math.round(value))
            }
            SettingSlider {
                label: Tr.t("Right padding")
                value: SettingsService.islandPaddingRight
                from: 0
                to: 64
                unit: " px"
                onMoved: value => SettingsService.set("islandPaddingRight", Math.round(value))
            }
            SettingSlider {
                label: Tr.t("Clock size in island")
                value: SettingsService.islandClockSize
                from: 14
                to: 28
                unit: " px"
                onMoved: value => SettingsService.setSharedClockSize(value)
            }
        }

        SettingGroup {
            visible:root.tab === "workspaces"
            title: Tr.t("Workspaces")
            note: Tr.t("Show and size the workspace indicator on either side of the clock.")
            SettingRow {
                label: Tr.t("Workspaces in island")
                ToggleSwitch {
                    checked: SettingsService.islandWorkspaces
                    onToggled: checked => SettingsService.set("islandWorkspaces", checked)
                }
            }
            SettingRow {
                label: Tr.t("Position")
                visible: SettingsService.islandWorkspaces
                SegmentedControl {
                    options: [
                        { id: "left", label: Tr.t("Left") },
                        { id: "right", label: Tr.t("Right") }
                    ]
                    current: SettingsService.islandWorkspacesPosition
                    onSelected: id => SettingsService.set("islandWorkspacesPosition", id)
                }
            }
            SettingSlider {
                visible: SettingsService.islandWorkspaces
                label: Tr.t("Horizontal offset")
                value: SettingsService.islandWorkspacesOffset
                from: -80
                to: 80
                unit: " px"
                onMoved: value => SettingsService.set("islandWorkspacesOffset", Math.round(value))
            }
            SettingSlider {
                visible: SettingsService.islandWorkspaces
                label: Tr.t("Size")
                value: SettingsService.islandWorkspacesScale
                from: 60
                to: 160
                unit: "%"
                onMoved: value => SettingsService.set("islandWorkspacesScale", Math.round(value))
            }
            SettingRow {
                visible: SettingsService.islandWorkspaces
                label: Tr.t("Active workspace glow")
                reading: Tr.t("Follows the active workspace colour")
                ToggleSwitch {
                    checked: SettingsService.islandWorkspacesGlow
                    onToggled: checked => SettingsService.set("islandWorkspacesGlow", checked)
                }
            }
        }

        SettingGroup {
            visible:root.tab === "network"
            title: Tr.t("Signal")
            note: Tr.t("Show and position the internet signal indicator.")
            SettingRow {
                label: Tr.t("Internet signal in island")
                ToggleSwitch {
                    checked: SettingsService.islandInternet
                    onToggled: checked => SettingsService.set("islandInternet", checked)
                }
            }
            SettingRow {
                label: Tr.t("Signal style")
                visible: SettingsService.islandInternet
                SegmentedControl {
                    options: [
                        { id: "bars", label: Tr.t("Bars") },
                        { id: "wifi", label: Tr.t("Wi-Fi") }
                    ]
                    current: SettingsService.islandInternetStyle
                    onSelected: id => SettingsService.set("islandInternetStyle", id)
                }
            }
            SettingRow {
                label: Tr.t("Position")
                visible: SettingsService.islandInternet
                SegmentedControl {
                    options: [
                        { id: "left", label: Tr.t("Left") },
                        { id: "right", label: Tr.t("Right") }
                    ]
                    current: SettingsService.islandInternetPosition
                    onSelected: id => SettingsService.set("islandInternetPosition", id)
                }
            }
            SettingSlider {
                visible: SettingsService.islandInternet
                label: Tr.t("Horizontal offset")
                value: SettingsService.islandInternetOffset
                from: -80
                to: 80
                unit: " px"
                onMoved: value => SettingsService.set("islandInternetOffset", Math.round(value))
            }
            SettingSlider {
                visible: SettingsService.islandInternet
                label: Tr.t("Size")
                value: SettingsService.islandInternetScale
                from: 60
                to: 160
                unit: "%"
                onMoved: value => SettingsService.set("islandInternetScale", Math.round(value))
            }
        }

        SettingGroup {
            visible:root.tab === "bluetooth"
            title: Tr.t("Bluetooth")
            note: Tr.t("Show the Bluetooth icon and open its devices when clicked.")
            SettingRow {
                label: Tr.t("Bluetooth in island")
                ToggleSwitch {
                    checked: SettingsService.islandBluetooth
                    onToggled: checked => SettingsService.set("islandBluetooth", checked)
                }
            }
            SettingRow {
                visible: SettingsService.islandBluetooth
                label: Tr.t("Position")
                SegmentedControl {
                    options: [
                        { id: "left", label: Tr.t("Left") },
                        { id: "right", label: Tr.t("Right") }
                    ]
                    current: SettingsService.islandBluetoothPosition
                    onSelected: id => SettingsService.set("islandBluetoothPosition", id)
                }
            }
            SettingSlider {
                visible: SettingsService.islandBluetooth
                label: Tr.t("Horizontal offset")
                value: SettingsService.islandBluetoothOffset
                from: -80
                to: 80
                unit: " px"
                onMoved: value => SettingsService.set("islandBluetoothOffset", Math.round(value))
            }
            SettingSlider {
                visible: SettingsService.islandBluetooth
                label: Tr.t("Size")
                value: SettingsService.islandBluetoothScale
                from: 60
                to: 160
                unit: "%"
                onMoved: value => SettingsService.set("islandBluetoothScale", Math.round(value))
            }
        }

        SettingGroup {
            visible:root.tab === "volume"
            title: Tr.t("Speaker")
            note: Tr.t("Show the output volume and open its module when clicked.")
            SettingRow {
                label: Tr.t("Speaker in island")
                ToggleSwitch {
                    checked: SettingsService.islandSpeaker
                    onToggled: checked => SettingsService.set("islandSpeaker", checked)
                }
            }
            SettingRow {
                visible: SettingsService.islandSpeaker
                label: Tr.t("Show volume percentage")
                ToggleSwitch {
                    checked: SettingsService.islandSpeakerPercent
                    onToggled: checked => SettingsService.set("islandSpeakerPercent", checked)
                }
            }
            SettingRow {
                visible: SettingsService.islandSpeaker
                label: Tr.t("Position")
                SegmentedControl {
                    options: [
                        { id: "left", label: Tr.t("Left") },
                        { id: "right", label: Tr.t("Right") }
                    ]
                    current: SettingsService.islandSpeakerPosition
                    onSelected: id => SettingsService.set("islandSpeakerPosition", id)
                }
            }
            SettingSlider {
                visible: SettingsService.islandSpeaker
                label: Tr.t("Horizontal offset")
                value: SettingsService.islandSpeakerOffset
                from: -80
                to: 80
                unit: " px"
                onMoved: value => SettingsService.set("islandSpeakerOffset", Math.round(value))
            }
            SettingSlider {
                visible: SettingsService.islandSpeaker
                label: Tr.t("Size")
                value: SettingsService.islandSpeakerScale
                from: 60
                to: 160
                unit: "%"
                onMoved: value => SettingsService.set("islandSpeakerScale", Math.round(value))
            }
        }

        SettingGroup {
            visible:root.tab === "battery"
            title: Tr.t("Battery")
            note: Tr.t("Choose its side, display, offset and size.")
            SettingRow {label:Tr.t("Battery glow");ToggleSwitch {checked:SettingsService.islandBatteryGlow;onToggled:value=>SettingsService.set("islandBatteryGlow",value)}}
            SettingRow {
                label: Tr.t("Battery icon style")
                SegmentedControl {
                    options: [{id:"old",label:Tr.t("Old")},{id:"new",label:Tr.t("New")},{id:"reference",label:Tr.t("Reference")}]
                    current: SettingsService.islandBatteryIconStyle
                    onSelected: id => SettingsService.set("islandBatteryIconStyle",id)
                }
            }
            SettingSlider {visible:SettingsService.islandBatteryIconStyle==="reference";label:Tr.t("Filled area brightness");from:0;to:100;unit:"%";value:SettingsService.islandBatteryFillOpacity;onMoved:value=>SettingsService.set("islandBatteryFillOpacity",Math.round(value))}
            SettingSlider {visible:SettingsService.islandBatteryIconStyle==="reference";label:Tr.t("Empty area brightness");from:0;to:100;unit:"%";value:SettingsService.islandBatteryEmptyOpacity;onMoved:value=>SettingsService.set("islandBatteryEmptyOpacity",Math.round(value))}
            SettingSlider {visible:SettingsService.islandBatteryIconStyle==="reference";label:Tr.t("Battery tip brightness");from:0;to:100;unit:"%";value:SettingsService.islandBatteryTipOpacity;onMoved:value=>SettingsService.set("islandBatteryTipOpacity",Math.round(value))}
            SettingRow {
                label: Tr.t("Battery in island")
                ToggleSwitch {
                    checked: SettingsService.islandBattery
                    onToggled: checked => SettingsService.set("islandBattery", checked)
                }
            }
            SettingRow {
                label: Tr.t("Position")
                visible: SettingsService.islandBattery
                SegmentedControl {
                    options: [
                        { id: "left", label: Tr.t("Left") },
                        { id: "right", label: Tr.t("Right") }
                    ]
                    current: SettingsService.islandBatteryPosition
                    onSelected: id => SettingsService.set("islandBatteryPosition", id)
                }
            }
            SettingRow {
                visible: SettingsService.islandBattery
                label: Tr.t("Battery display")
                SegmentedControl {
                    options: [
                        { id: "icon", label: Tr.t("Icon") },
                        { id: "both", label: Tr.t("Icon + %") },
                        { id: "percent", label: Tr.t("% only") }
                    ]
                    current: SettingsService.islandBatteryMode
                    onSelected: id => SettingsService.set("islandBatteryMode", id)
                }
            }
            SettingSlider {
                visible: SettingsService.islandBattery
                label: Tr.t("Horizontal offset")
                value: SettingsService.islandBatteryOffset
                from: -80
                to: 80
                unit: " px"
                onMoved: value => SettingsService.set("islandBatteryOffset", Math.round(value))
            }
            SettingSlider {
                visible: SettingsService.islandBattery
                label: Tr.t("Size")
                value: SettingsService.islandBatteryScale
                from: 60
                to: 160
                unit: "%"
                onMoved: value => SettingsService.set("islandBatteryScale", Math.round(value))
            }
        }
    }

    // ── NOTIFICATIONS ───────────────────────────────────────────────────────

    SettingGroup {
        visible: root.tab === "notifications"
        title: Tr.t("Notifications")
        note: Tr.t("New notifications appear briefly in the island.")
        hint: Tr.t("The shell is the notification daemon: notifications without their own timeout use the time below, and critical ones stay until dismissed. Do not disturb only keeps them off the screen; they still collect in the control centre until the shell restarts.")

        // Locked while Do not disturb is on, since nothing is shown.
        SettingSlider {
            label: Tr.t("How long one stays")
            value: SettingsService.notificationTimeout / 1000
            from: 2
            to: 15
            unit: " s"
            locked: NotificationService.doNotDisturb
            reason: Tr.t("Nothing is shown while Do not disturb is on")
            onMoved: value => SettingsService.set(
                "notificationTimeout", Math.round(value) * 1000)
        }

        SettingRow {
            label: Tr.t("Do not disturb")
            reading: NotificationService.doNotDisturb
                ? Tr.t("Nothing takes the screen")
                : Tr.t("Everything is shown")

            ToggleSwitch {
                checked: NotificationService.doNotDisturb
                onToggled: NotificationService.toggleDoNotDisturb()
            }
        }

        SettingRow {
            label: Tr.t("Kept")
            reading: NotificationService.history.length > 0
                ? `${NotificationService.history.length} ${Tr.t("in this session")}`
                : Tr.t("Nothing kept")

            PillButton {
                text: Tr.t("Clear")
                icon: "󰜉"
                implicitWidth: 92
                implicitHeight: 30
                enabled: NotificationService.history.length > 0
                onClicked: NotificationService.clearHistory()
            }
        }
    }
}
