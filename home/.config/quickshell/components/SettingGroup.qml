// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G   G R O U P                                              │
// │   settings · a titled card of rows                                       │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts

import "../theme"
import "../services"

// Its heading, then one card holding the group's rows, divided by hairlines.
// `bare` leaves the card out, for a control that draws its own surface.
ColumnLayout { objectName:"design:SettingGroup:1";
    id: root

    property string title: ""

    // Both open behind the heading's info glyph.
    property string note: ""
    property string hint: ""

    property bool helpExpanded:false
    property bool bare: false
    readonly property bool forma:Theme.formaIn(QsWindow.window)
    readonly property bool modern:Theme.modernIn(QsWindow.window)

    // The page host owns one consistent entry animation for every page.
    default property alias rows: list.data

    Layout.fillWidth: true
    spacing: 7

    GroupHeading {
        visible:root.title!=="" && (!root.forma || root.modern)
        title: root.title
        note: root.note
        hint: root.hint
    }

    Rectangle { objectName:"design:SettingGroup:2";
        Layout.fillWidth: true
        implicitHeight: list.implicitHeight
        radius:SettingsDesignService.style.cardRadius
        color: root.bare||SettingsDesignService.style.outline?"transparent":SettingsDesignService.forma && !root.forma?Theme.surfaceIn(QsWindow.window):SettingsDesignService.style.cardBackground||Theme.surfaceIn(QsWindow.window)
        border.color:SettingsDesignService.forma && !root.forma?Theme.borderIn(QsWindow.window):SettingsDesignService.style.navigation === "studio" ? SettingsDesignService.style.borderColor : SettingsDesignService.style.outline?Qt.alpha(Theme.accentIn(QsWindow.window),.32):Theme.borderIn(QsWindow.window)
        border.width:root.bare?0:root.forma?SettingsDesignService.style.borderWidth:1


        ColumnLayout { objectName:"design:SettingGroup:3";
            id: list

            width: parent.width
            ColumnLayout {
                visible:root.forma && !root.modern && root.title!=="" && SettingsDesignService.style.showCardTitles!==false
                Layout.fillWidth:true;Layout.margins:SettingsDesignService.style.cardPadding;spacing:5
                RowLayout {Layout.fillWidth:true
                    Text {Layout.fillWidth:true;text:root.title;font.family:SettingsDesignService.style.headingFont||Theme.fontIn(QsWindow.window);font.pixelSize:15;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window)}
                    Text {visible:root.hint!==""&&SettingsDesignService.style.showHelp;text:"󰋼";font.family:Theme.fontMono;font.pixelSize:13;color:Theme.mutedIn(QsWindow.window)
                        TapHandler {onTapped:root.helpExpanded=!root.helpExpanded}
                    }
                }
                Text {visible:root.helpExpanded&&SettingsDesignService.style.showHelp;Layout.fillWidth:true;text:root.hint;wrapMode:Text.WordWrap;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.mutedIn(QsWindow.window)}
                Text {visible:root.note!=="";Layout.fillWidth:true;text:root.note;wrapMode:Text.WordWrap;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:12;color:Theme.mutedIn(QsWindow.window)}
            }
            spacing: root.bare ? 10 : 0
        }
    }
}
