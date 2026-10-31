// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I S L A N D   R E S T                                                  │
// │   resting island · the clock and running activities                      │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import Quickshell.Widgets

import "../../theme"
import "../../services"
import "../../components"
import "../modules"

// The island at rest: the clock in the middle, with a recording, countdown or
// track either side while one is running (one item split across both sides,
// mark leading and figure trailing, or one item per side).
//
// A recording stops with one click here, since nothing else on screen can stop
// it; the dot squares off under the pointer to show that. A countdown or a
// track opens its detail.
Item { objectName:"design:IslandRest:1";
    id: root

    property var configuration:IslandPresetService.presentation
    property bool preview:false
    property bool designMode:false
    property real coreWidth:ModuleService.clockCore
    property real sideWidth:ModuleService.activitySide
    readonly property var activities: root.preview
        ? ((MediaService.playing || root.designMode) && (root.configuration.islandActivities||SettingsService.besideDefaults||[]).includes("media")?["media"]:[]) : ModuleService.activities
    readonly property bool split: root.activities.length === 1

    // A side under the pointer holds the glance off, so a click on the dot
    // never lands on a summary that opened under it.
    readonly property bool busy: leading.hovered || trailing.hovered || islandClock.busy

    // What did not fit takes a slot at the trailing end; the time keeps
    // the middle of the rest.
    readonly property int spare: root.preview ? 0 : ModuleService.overflow > 0 ? ModuleService.overflowWidth : 0

    ClockModule {
        id: islandClock
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -root.spare / 2
        configuration:root.configuration
        preview:root.preview
        width: root.activities.length > 0 ? root.coreWidth : parent.width
        height: Theme.capsuleHeight
        onSummaryRequested: ModuleService.togglePanel(
            SettingsService.islandSummaryMode === "hover" ? "controls" : "summary")
    }

    Segment {
        id: leading

        anchors.left: parent.left
        width: root.sideWidth
        height: parent.height
        visible: root.activities.length > 0
        activityId: root.activities[0] ?? ""
        part: root.split ? "mark" : "both"
    }

    Segment {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: root.spare
        width: root.sideWidth
        height: parent.height
        visible: root.activities.length > 0
        activityId: root.split ? (root.activities[0] ?? "") : (root.activities[1] ?? "")
        part: root.split ? "figure" : "both"
    }

    // How many more are running than fit; the glance lists them.
    Rectangle { objectName:"design:IslandRest:2";
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: ModuleService.overflow > 0
        width: ModuleService.overflowWidth - 6
        height: 18
        radius: height / 2
        color: Theme.islandSurface

        Text { objectName:"design:IslandRest:3";
            anchors.centerIn: parent
            text: `+${ModuleService.overflow}`
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLabel
            font.weight: Font.DemiBold
            color: Theme.moduleColour("clock","muted",Theme.textMuted)
        }
    }

    component Segment: Item {
        id: segment

        property string activityId: ""

        // "mark", "figure", or "both".
        property string part: "both"

        readonly property alias hovered: mouse.containsMouse

        readonly property var marks: ({
            recorder: recorderMark, privacy: privacyMark, timer: timerMark, media: mediaMark,
            machine: machineMark, workspace: workspaceMark
        })
        readonly property var figures: ({
            recorder: recorderFigure, privacy: privacyFigure, timer: timerFigure, media: mediaFigure,
            machine: machineFigure, workspace: workspaceFigure
        })

        // Centred on its side, except the privacy mark split across both:
        // its glyphs and the program's name each keep to their outer edge,
        // by the same margin, so the pair is symmetric about the time.
        readonly property bool hugs: segment.activityId === "privacy" && segment.part !== "both"

        Row { objectName:"design:activity-"+segment.activityId+"-"+segment.part;
            anchors.verticalCenter: parent.verticalCenter
            x: !segment.hugs ? (parent.width - width) / 2
                : segment.part === "mark" ? ModuleService.activityInset
                : parent.width - width - ModuleService.activityInset
            spacing: 7

            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active: segment.part !== "figure" && segment.activityId !== ""
                visible: active
                sourceComponent: segment.marks[segment.activityId] ?? null
            }

            // Sharing the island, the privacy mark is its glyphs alone: a
            // side of two activities has no room for a program's name.
            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active: segment.part !== "mark" && segment.activityId !== ""
                    && !(segment.activityId === "privacy" && segment.part === "both")
                visible: active
                sourceComponent: segment.figures[segment.activityId] ?? null
            }
        }

        // The privacy mark has nothing to open, so its sides take neither the
        // pointer nor a click: over them the island does what it does over
        // the time, the glance and then the control centre.
        MouseArea {
            id: mouse

            anchors.fill: parent
            enabled: segment.activityId !== "privacy"
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (segment.activityId === "recorder")
                    RecorderService.toggle()
                else if (segment.activityId === "workspace")
                    ModuleService.togglePanel("overview")
                else if (segment.activityId === "machine")
                    ModuleService.togglePanel("machines")
                else
                    ModuleService.activate(segment.activityId)
            }
        }

        // ── RECORDING ───────────────────────────────────────────────────────
        //
        // `indicatorBad`, not the palette's red: warnings do not follow the
        // palette. It breathes rather than blinks, and under the pointer it
        // stops and squares off into a stop button.
        Component {
            id: recorderMark

            Rectangle { objectName:"design:IslandRest:5";
                width: segment.hovered ? 9 : 8
                height: width
                radius: segment.hovered ? 2 : width / 2
                color: Theme.indicatorBad

                Behavior on radius { NumberAnimation { duration: Theme.durationFast } }

                SequentialAnimation on opacity {
                    running: !segment.hovered && Theme.lively
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) parent.opacity = 1
                    NumberAnimation { to: 0.4; duration: 900; easing.type: Theme.easing }
                    NumberAnimation { to: 1;   duration: 900; easing.type: Theme.easing }
                }
            }
        }

        Component {
            id: recorderFigure

            Text { objectName:"design:IslandRest:6";
                text: RecorderService.display
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.moduleColour("clock","foreground",Theme.text)
            }
        }

        // ── PRIVACY ─────────────────────────────────────────────────────────
        //
        // What is in use, each in its fixed colour, and who is using it.
        Component {
            id: privacyMark

            Row { objectName:"design:IslandRest:7";
                spacing: 6

                Repeater {
                    model: [
                        { on: PrivacyService.microphone, glyph: "󰍬", tint: Theme.privacyMicrophone },
                        { on: PrivacyService.cameraOn,   glyph: "󰄀", tint: Theme.privacyCamera },
                        { on: PrivacyService.screen,     glyph: "󰍹", tint: Theme.privacyScreen }
                    ].filter(kind => kind.on)

                    Text { objectName:"design:IslandRest:8";
                        required property var modelData

                        text: modelData.glyph
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeRegular + 1
                        color: modelData.tint
                    }
                }
            }
        }

        Component {
            id: privacyFigure

            Text { objectName:"design:IslandRest:9";
                width: Math.min(implicitWidth, ModuleService.privacyNameLimit,
                                root.sideWidth - 2 * ModuleService.activityInset)
                text: PrivacyService.who
                elide: Text.ElideRight
                // The time's type, muted: the name is the lesser of the two.
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                font.weight: Font.DemiBold
                color: Theme.moduleColour("clock","muted",Theme.textMuted)
            }
        }

        // ── COUNTDOWN ───────────────────────────────────────────────────────
        Component {
            id: timerMark

            RingIndicator {
                width: 16
                height: 16
                thickness: 2
                progress: TimerService.progress
                trackColor: Theme.indicatorDim
                fillColor: TimerService.tint
            }
        }

        Component {
            id: timerFigure

            Text { objectName:"design:IslandRest:10";
                text: TimerService.display
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: TimerService.paused ? Theme.moduleColour("clock","muted",Theme.textMuted) : Theme.moduleColour("clock","foreground",Theme.text)
            }
        }

        // ── TRACK ───────────────────────────────────────────────────────────
        //
        // The artwork, and the real spectrum: bars animated on a timer keep
        // moving through silence.
        Component {
            id: mediaMark

            ClippingRectangle { objectName:"design:media-artwork";
                id:mediaArtwork
                readonly property bool designManaged:true
                ElementOverride{target:mediaArtwork;moduleId:"bar";elementKey:"design:media-artwork";designSource:root.preview&&!root.designMode?(root.configuration.barElementLayout?.["design:media-artwork"]||{}):null}
                width: 20
                height: 20
                radius: width * Theme.pictureCorner
                // None behind a picture: a player may send its logo on transparency.
                color: art.visible ? "transparent" : Theme.surfaceHoverIn(QsWindow.window)

                Component.onCompleted: MediaService.subscribe()
                Component.onDestruction: MediaService.release()

                Image { objectName:"design:IslandRest:12";
                    id: art
                    anchors.fill: parent
                    source: MediaService.artUrl
                    visible: source != "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 40
                    sourceSize.height: 40
                }

                Text { objectName:"design:IslandRest:13";
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "󰎇"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.moduleColour("clock","accent",Theme.indicator)
                }
            }
        }

        Component {
            id: mediaFigure

            Spectrum {
                id:mediaSpectrum
                objectName:"design:media-spectrum"
                readonly property bool designManaged:true
                ElementOverride{target:mediaSpectrum;moduleId:"bar";elementKey:"design:media-spectrum";designSource:root.preview&&!root.designMode?(root.configuration.barElementLayout?.["design:media-spectrum"]||{}):null}
                height: 14
                barWidth: 2
                minimum: 2
                previewValues:root.preview?[.18,.35,.7,.9,.65,.45,.8,.55,.3,.18]:null
                active: MediaService.playing
                barColor: Theme.moduleColour("clock","accent",Theme.indicator)

                Component.onCompleted: if(!root.preview) CavaService.subscribe()
                Component.onDestruction: if(!root.preview) CavaService.release()
            }
        }

        // ── A VIRTUAL MACHINE ───────────────────────────────────────────────
        //
        // The system's mark, and how long it has run; with more than one
        // running, how many.
        Component {
            id: machineMark

            Text { objectName:"design:IslandRest:14";
                text: VmService.mark(VmService.running[0]?.os ?? "")
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeMedium
                color: VmService.running[0]?.paused ? Theme.moduleColour("clock","muted",Theme.textMuted) : Theme.moduleColour("clock","foreground",Theme.text)
            }
        }

        Component {
            id: machineFigure

            Text { objectName:"design:IslandRest:15";
                width: Math.min(implicitWidth, root.sideWidth - 2 * ModuleService.activityInset)
                elide: Text.ElideRight
                text: VmService.running.length > 1 ? `${VmService.running.length} ${Tr.t("running")}`
                    : VmService.uptime(VmService.running[0]?.started ?? 0)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.moduleColour("clock","foreground",Theme.text)
            }
        }

        // ── WORKSPACE ───────────────────────────────────────────────────────
        //
        // The one this screen shows, for a bar without the workspaces strip:
        // its number, or its name when it has one, in the privacy name's type.
        // A click opens the overview.
        Component {
            id: workspaceMark

            Text { objectName:"design:IslandRest:16";
                text: "󰕰"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeRegular + 1
                color: Theme.moduleColour("clock","muted",Theme.textMuted)
            }
        }

        Component {
            id: workspaceFigure

            // A new label slides in from below when the workspace is further
            // along and from above when it is back, and the old one out the
            // other way.
            Item { objectName:"design:IslandRest:17";
                id: shown

                readonly property string screenName: QsWindow.window && QsWindow.window.screen
                    ? QsWindow.window.screen.name : ""
                readonly property int number: HyprlandService.activeOn(shown.screenName)
                    || HyprlandService.activeId
                readonly property string label: {
                    const found = HyprlandService.named.find(workspace => workspace.id === shown.number)
                    const name = found && typeof found.name === "string" ? found.name : ""
                    return name !== "" && name !== `${shown.number}` ? name
                        : `${HyprlandService.numberOn(shown.number, shown.screenName)}`
                }

                property int was: 0
                property string settled: ""
                property string leaving: ""
                property real travel: 0

                width: Math.min(Math.max(incoming.implicitWidth, outgoing.visible ? outgoing.implicitWidth : 0),
                                root.sideWidth - 2 * ModuleService.activityInset)
                height: incoming.implicitHeight
                clip: true

                onNumberChanged: {
                    const forward = shown.number > shown.was
                    shown.leaving = shown.settled
                    shown.settled = shown.label
                    shown.was = shown.number
                    slide.stop()
                    shown.travel = forward ? 1 : -1
                    slide.start()
                }

                Component.onCompleted: {
                    shown.was = shown.number
                    shown.settled = shown.label
                }

                NumberAnimation {
                    id: slide

                    target: shown
                    property: "travel"
                    to: 0
                    duration: Theme.durationMedium
                    easing.type: Theme.easing
                }

                Text { objectName:"design:IslandRest:18";
                    id: outgoing

                    visible: shown.travel !== 0
                    y: (shown.travel - Math.sign(shown.travel)) * shown.height
                    width: shown.width
                    text: shown.leaving
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Font.DemiBold
                    color: Theme.moduleColour("clock","muted",Theme.textMuted)
                }

                Text { objectName:"design:IslandRest:19";
                    id: incoming

                    y: shown.travel * shown.height
                    width: shown.width
                    text: shown.label
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Font.DemiBold
                    color: Theme.moduleColour("clock","muted",Theme.textMuted)
                }
            }
        }
    }
}
