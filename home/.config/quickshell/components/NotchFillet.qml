// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   N O T C H   F I L L E T                                                │
// │   the concave corner where the notch meets the screen edge               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell

import "../theme"

// A concave fillet where the notch meets the bezel. Rectangle `radius` only
// rounds corners inward, so this is drawn: the square minus a disc centred
// on its far corner.
Item { objectName:"design:NotchFillet:1";
    id: root

    property color color: Theme.colourIn(QsWindow.window,"cardBackground",Theme.islandGround)
    // Mirrored, for the notch's left side.
    property bool mirrored: false
    // How far down the glass's light from the top reaches in the shape the
    // fillet flares from (`GlassSheen`); 0 for none.
    property real sheenReach: 0
    // Opaque faces overlap the body internally to close fractional-scale seams.
    property real joinOverlap: 0

    implicitWidth: Theme.radiusNotch * 2
    implicitHeight: Theme.radiusNotch * 2
    // Analytic coverage avoids rebuilding and tessellating a SVG at every
    // frame of the island morph, including its shadow copies.
    ShaderEffect {
        anchors.fill:parent
        property color fillInk:root.color
        property color sheenInk:Theme.sheenOf(Theme.surfaceStyle)
        property vector2d boxSize:Qt.vector2d(width,height)
        property real power:Theme.notchShoulderRoundingPower
        property real mirrored:root.mirrored?1:0
        property real sheenReach:root.sheenReach
        property real joinOverlap:root.joinOverlap
        fragmentShader:Qt.resolvedUrl("../shaders/notch-fillet.frag.qsb")
    }
}
