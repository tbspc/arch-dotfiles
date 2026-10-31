import QtQuick
import "../theme"
import "../services"
Text {
    property int size:32
    text:"󰣇"
    font.family:Theme.fontOf("Symbols Nerd Font, JetBrainsMono Nerd Font, monospace")
    font.pixelSize:size
    color:ThemeService.dynamicColors?.accent || Theme.accent
    horizontalAlignment:Text.AlignHCenter
    verticalAlignment:Text.AlignVCenter
}
