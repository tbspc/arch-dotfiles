// Fixed-position profile and password prompt for the secure lock.
import QtQuick

import "../theme"
import "../services"
import "../components"
import "common"

Item {
    id: root

    signal submitted(string password)

    property var configuration: LockStyleService.values
    property Item glassSource:null
    property bool preview: false
    property bool previewAwake: false
    property bool previewFailed: false
    property bool previewCaps: false
    readonly property bool failure: root.preview ? root.previewFailed : LockService.failed
    readonly property bool caps: root.preview ? root.previewCaps : root.capsLockOn
    readonly property color ink: configuration.lockTextColor
    readonly property int nameY: 18 + configuration.lockAvatarSize + configuration.lockProfileGap
    readonly property int promptY: root.nameY + configuration.lockNameSize + configuration.lockPromptGap
    readonly property bool activeEntry: root.preview ? root.previewAwake : LockService.awake || field.text !== ""
        || LockService.authenticating || LockService.failed
    property bool capsLockOn: false
    readonly property int fieldWidth: configuration.lockFieldWidth

    implicitWidth: Math.max(root.fieldWidth, configuration.lockAvatarSize + 32)
    implicitHeight: root.promptY + configuration.lockFieldHeight + 41

    function claim(): void { if (!root.preview) field.forceActiveFocus() }
    function clear(): void { field.clear() }

    ReferenceProfile {
        visible:root.configuration.lockDesign==="reference"
        anchors.horizontalCenter:parent.horizontalCenter;y:18
        width:root.configuration.lockAvatarSize;height:width;ink:root.ink
    }
    Avatar {
        visible:root.configuration.lockDesign!=="reference"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        width: root.configuration.lockAvatarSize
        height: width
        source: AccountService.avatar
        initials: AccountService.initials
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.nameY
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text:root.configuration.lockDesign==="reference"?(AccountService.user||"tbs"):AccountService.name
        font.family: root.configuration.lockFontFamily
        font.pixelSize: root.configuration.lockNameSize
        font.weight: Font.DemiBold
        color: root.ink
    }

    // Occupies the exact center point used by the idle hint below.
    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.promptY
        width: root.fieldWidth
        height: root.configuration.lockFieldHeight
        radius: height / 2
        color: root.configuration.lockFieldMaterial==="tahoe"?"transparent":Qt.rgba(1, 1, 1, root.configuration.lockFieldOpacity / 100)
        border.width: 1
        border.color: root.failure ? Qt.rgba(1, 0.42, 0.40, 0.78)
            : root.caps ? Qt.rgba(1, 0.78, 0.40, 0.72)
            : Qt.rgba(1, 1, 1, root.configuration.lockFieldBorderOpacity / 100)
        opacity: root.activeEntry ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
        Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

        Loader {
            anchors.fill:parent
            active:root.configuration.lockFieldMaterial==="tahoe" && root.glassSource!==null
            sourceComponent:MacGlassPane {
                backdrop:root.glassSource
                readonly property point location:{const geometry=root.x+root.y+root.width+root.height+root.promptY+width+height;return mapToItem(root.glassSource,0,0)}
                sourceX:location.x;sourceY:location.y;cornerRadius:height/2
                glassThickness:16;glassBlur:root.configuration.lockGlassBlur??5;glassTint:root.configuration.lockGlassTint??35
                refraction:root.configuration.lockGlassRefraction??80;shine:root.configuration.lockGlassShine??30
            }
        }
        TextInput {
            id: field
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            echoMode: TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            enabled: !root.preview && !LockService.authenticating && !LockService.leaving
            font.family: root.configuration.lockFontFamily
            font.pixelSize: Theme.fontSizeRegular
            color: root.ink
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: root.preview && root.previewAwake ? "● ● ● ● ●" : root.configuration.lockPlaceholder
                font: field.font
                color: root.ink
                opacity: field.text.length === 0 ? 0.78 : 0
                visible: opacity > 0
            }

            Connections {
                target: root.preview ? null : LockService
                function onTypedChanged(): void {
                    if (field.text !== LockService.typed)
                        field.text = LockService.typed
                }
            }

            onAccepted: {
                root.submitted(field.text)
                field.clear()
            }

            onTextChanged: {
                if (root.preview) return
                if (field.text !== LockService.typed)
                    LockService.typed = field.text
                if (LockService.failed && field.text !== "")
                    LockService.failed = false
            }

            Keys.onEscapePressed: {
                field.clear()
                LockService.rest()
            }

            Keys.onPressed: event => {
                if(!root.activeEntry&&(event.key===Qt.Key_Return||event.key===Qt.Key_Enter)){
                    LockService.rouse();event.accepted=true;return
                }
                if (event.key === Qt.Key_CapsLock) {
                    root.capsLockOn = !root.capsLockOn
                    return
                }
                if (event.key === Qt.Key_Shift || event.key === Qt.Key_Escape)
                    return
                event.accepted = false
                LockService.rouse()
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.promptY + (root.configuration.lockFieldHeight - 16) / 2
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        visible: root.configuration.lockHint
        textFormat: Text.PlainText
        text: root.configuration.lockIdleHint
        font.family: root.configuration.lockFontFamily
        font.pixelSize:root.configuration.lockDesign==="reference"?15:12
        color: root.ink
        opacity: root.activeEntry ? 0 : 0.62
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.promptY + root.configuration.lockFieldHeight + 4
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        visible:root.configuration.lockDesign!=="reference"
        text: (root.preview ? (root.previewFailed ? "Wrong password" : "") : LockService.message) || (root.caps
            ? "Caps Lock is on" : "Enter your password to unlock")
        font.family: root.configuration.lockFontFamily
        font.pixelSize: 11
        color: root.failure ? Qt.rgba(1, 0.56, 0.53, 1)
            : root.caps ? Qt.rgba(1, 0.82, 0.55, 1) : root.ink
        opacity: root.activeEntry ? 0.72 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
    }
}
