// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   I S L A N D   M O T I O N   P R E V I E W                              │
// │   the island opening and closing, at one preset's pace                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../theme"
import "../services"
import "SpringMotion.js" as SpringMotion
import "MotionTrace.js" as MotionTrace

// The island morphing between its resting capsule and a panel, using the
// motion preset being previewed.
Item { objectName:"design:IslandMotionPreview:1";
    id: root

    // A row from `Theme.motionPresets`.
    property var preset: null
    property bool animate: true

    readonly property var spring:root.preset?.settings?.shellSpring||({})
    readonly property bool reference:spring.enabled===true
    readonly property int referenceDuration:Math.round((isle.open?root.spring.openDuration:root.spring.closeDuration)*(root.preset?.scale??100)/100)
    readonly property var physicsCurve:root.reference?(root.spring.mode==="traced"?MotionTrace.profile(isle.open?"hover-open":"hover-close").width:SpringMotion.curve(root.referenceDuration,root.spring.damping,isle.open?root.spring.openFrequency:root.spring.closeFrequency)):[]
    readonly property real pace: root.preset ? root.preset.scale / 100*(root.preset.settings?.shellExpandDuration??380)/380 : 1
    readonly property bool still: root.pace === 0

    implicitWidth: 92
    implicitHeight: entrance.bouncy ? 56 : 44

    ViewMotion {
        id: entrance
        useShellSettings:false
        curve: root.reference?"OutCubic":root.preset ? root.preset.curve : "OutCubic"
        pace: root.pace
        triggerKey: isle.open ? "preview" : ""
    }

    Rectangle { objectName:"design:IslandMotionPreview:2";
        id: isle

        property bool open: false

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + entrance.offset * 0.7
        opacity: isle.open ? entrance.contentOpacity : 1
        transform: Scale {
            origin.x: isle.width / 2
            origin.y: isle.height / 2
            xScale: entrance.stretchX
            yScale: entrance.stretchY
        }
        width: isle.open ? parent.width - 8 : 46
        height: isle.open ? parent.height - (entrance.bouncy ? 24 : 12) : 16
        radius: height / 2
        color: Theme.accentIn(QsWindow.window)

        Behavior on width {
            enabled: !root.still
            ConfiguredNumberAnimation {
                spring:1.70158*(root.preset?.settings?.shellShapeSpring??SettingsService.shellShapeSpring)/100
                duration:root.reference?root.referenceDuration:380*root.pace
                customCurve:root.physicsCurve
                curve: isle.open && root.preset
                    ? Theme.easingTypeOf(root.preset.curve) : Easing.OutCubic
            }
        }

        Behavior on height {
            enabled: !root.still
            ConfiguredNumberAnimation {
                spring:1.70158*(root.preset?.settings?.shellShapeSpring??SettingsService.shellShapeSpring)/100
                duration:root.reference?root.referenceDuration:380*root.pace
                customCurve:root.physicsCurve
                curve: isle.open && root.preset
                    ? Theme.easingTypeOf(root.preset.curve) : Easing.OutCubic
            }
        }

        Row {
            visible:root.reference
            anchors.left:parent.left;anchors.leftMargin:9;anchors.verticalCenter:parent.verticalCenter;spacing:3
            Repeater {model:3;Rectangle {width:3;height:6;radius:1.5;color:Theme.accentTextIn(QsWindow.window);opacity:index===0?1:.35}}
        }
        Text {visible:root.reference;anchors.centerIn:parent;text:"12:34";font.pixelSize:8;color:Theme.accentTextIn(QsWindow.window)}
        Timer {
            interval: 1300
            running: root.animate && !root.still
            repeat: true
            triggeredOnStart: true
            onTriggered: isle.open = !isle.open
        }
    }
}
