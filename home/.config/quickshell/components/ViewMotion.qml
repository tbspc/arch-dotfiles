import QtQuick
import "../services"

// A shared entrance motion for real island views and their settings previews.
// The capsule itself keeps a smooth size curve; small displacements provide
// the bounce without stretching a large panel by tens of pixels.
Item { objectName:"design:ViewMotion:1";
    id: root

    property string curve: "OutCubic"
    property string triggerKey: ""
    property real pace: 1
    property real phase: 1
    property bool ready: true
    property bool useShellSettings:true

    readonly property bool bouncy: ["OutBounce", "OutElastic", "InOutBack"].indexOf(curve) >= 0
    readonly property bool fading: ["FadeSoft", "FadeRise", "FadeZoom"].indexOf(curve) >= 0
    readonly property bool special: bouncy || fading
    readonly property int baseDuration: curve === "OutElastic" ? 600
        : curve === "InOutBack" ? 560 : bouncy ? 520
        : curve === "FadeRise" ? 320 : curve === "FadeZoom" ? 300 : 260

    function smooth(t: real): real {
        const p = Math.max(0, Math.min(1, t))
        return p * p * p * (p * (p * 6 - 15) + 10)
    }

    function bounceAt(t: real): real {
        if (!root.bouncy || t <= 0 || t >= 1)
            return 0
        const frequency = (root.curve === "OutElastic" ? 2.5
            : root.curve === "InOutBack" ? 1.5 : 1)*(root.useShellSettings?SettingsService.shellBounceCycles/100:1)
        const amplitude = root.curve === "OutElastic" ? 32
            : root.curve === "InOutBack" ? -24 : 26
        // Both end velocities are zero. The envelope gently damps each hop.
        return amplitude * (root.useShellSettings?SettingsService.shellBounceStrength/100:1) * Math.sin(2 * Math.PI * frequency * t)
            * Math.sin(Math.PI * t) * Math.exp(-1.25 * t*(root.useShellSettings?SettingsService.shellBounceDamping/100:1))
    }

    readonly property real offset: (root.bouncy ? root.bounceAt(root.phase)
        : root.curve === "FadeRise" ? (root.useShellSettings?SettingsService.shellFadeDistance:8) * (1 - root.smooth(root.phase)) : 0)*(root.useShellSettings?SettingsService.shellMovement/100:1)
    readonly property real contentOpacity: root.fading ? root.smooth(root.phase) : 1
    readonly property real stretchX: root.curve === "FadeZoom"
        ? 1 - (root.useShellSettings?SettingsService.shellZoomAmount/100:.03)*(1-root.smooth(root.phase))*(root.useShellSettings?SettingsService.shellMovement/100:1)
        : root.curve === "InOutBack" ? 1 + root.offset / 1800 : 1
    readonly property real stretchY: root.curve === "FadeZoom" ? root.stretchX
        : root.curve === "InOutBack" ? 1 - root.offset / 1400 : 1

    function restart(): void {
        travel.stop()
        if (!root.ready) { root.phase = root.special && root.triggerKey !== "" ? 0 : 1; return }
        if (root.triggerKey !== "" && root.pace > 0 && root.special)
            travel.restart()
        else
            root.phase = 1
    }

    onReadyChanged: root.restart()
    onTriggerKeyChanged: root.restart()
    onCurveChanged: root.restart()
    onPaceChanged: root.restart()
    Component.onCompleted: root.restart()

    NumberAnimation {
        id: travel
        target: root
        property: "phase"
        from: 0
        to: 1
        duration: Math.round(root.baseDuration * root.pace * (root.useShellSettings?SettingsService.shellExpandDuration/380:1) * (root.fading&&root.useShellSettings?SettingsService.shellFadeDuration/100:1))
        easing.type: Easing.Linear
    }
}
