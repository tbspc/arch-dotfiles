// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G   D I V I D E R                                          │
// │   settings · the hairline between two rows                               │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick

import Quickshell
import "../theme"
import "../services"

// Drawn by the lower of two rows in a `SettingGroup`, and only when there is
// a row above it: the first visible row sits at the top of the card.
Rectangle { objectName:"design:SettingDivider:1";
    visible:parent!==null && parent.y>0 && (!Theme.formaIn(QsWindow.window)||SettingsDesignService.style.rowDivider)
    width: parent ? parent.width : 0
    height: 1
    color: Theme.borderIn(QsWindow.window)
}
