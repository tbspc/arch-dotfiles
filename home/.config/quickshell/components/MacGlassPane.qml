import QtQuick
import QtQuick.Effects

// Adapted from MacShell (MIT, shaders/MacShell-LICENSE).
// Pure Qt: also usable by the boot greeter; never captures the desktop itself.
Item {
    id:root
    required property Item backdrop
    property real sourceX:0
    property real sourceY:0
    property real cornerRadius:16
    property bool attached:false
    property bool dark:true
    property real glassBlur:5
    property real glassTint:42
    property real refraction:100
    property real shine:30
    property real glassThickness:24
    readonly property real margin:64
    readonly property real bx:Math.max(0,sourceX-margin)
    readonly property real by:Math.max(0,sourceY-margin)
    readonly property real bw:Math.max(1,Math.min(backdrop.width,sourceX+width+margin)-bx)
    readonly property real bh:Math.max(1,Math.min(backdrop.height,sourceY+height+margin)-by)
    ShaderEffectSource {
        id:raw
        sourceItem:root.backdrop
        sourceRect:Qt.rect(root.bx,root.by,root.bw,root.bh)
        textureSize:Qt.size(Math.ceil(root.bw*.75),Math.ceil(root.bh*.75))
        hideSource:false;live:root.visible;mipmap:true;visible:false
    }
    MultiEffect {
        id:preBlur
        source:raw;width:root.bw;height:root.bh
        blurEnabled:root.glassBlur>0;blurMax:32
        blur:Math.min(1,root.glassBlur*1.4/32)
        autoPaddingEnabled:false;visible:false
    }
    ShaderEffectSource {id:blurred;sourceItem:preBlur;live:root.visible;mipmap:true;visible:false}
    ShaderEffect {
        anchors.fill:parent
        fragmentShader:Qt.resolvedUrl("../shaders/macshell-liquid.frag.qsb")
        property variant src:blurred
        property vector2d itemSize:Qt.vector2d(width,height)
        property vector2d glassSize:Qt.vector2d(width,height)
        property vector2d srcSize:Qt.vector2d(root.bw,root.bh)
        property vector2d srcOffset:Qt.vector2d(root.sourceX-root.bx,root.sourceY-root.by)
        property real pad:0
        property real radius:root.cornerRadius
        property real bezel:Math.min(root.height*.36,26)
        property real thickness:root.glassThickness*root.refraction/100*1.6
        property real dispersion:0
        property real magnify:.05*root.refraction/100*1.6
        property real rim:root.shine/100*.45
        property real grain:.006
        property real blurPx:root.glassBlur>0?1.5:0
        property real tintMix:root.glassTint/100*.55
        property real saturation:1.25
        property real dark:root.dark?1:0
        property real debug:0
        property real shadowAmt:0
        property real rimTint:1
        property real ringW:0
        property real attached:root.attached?1:0
        property real flatInner:1
    }
}
