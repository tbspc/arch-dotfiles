import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import Quickshell
import "../services"
import "../theme"
SettingRow {
    id:root
    property string colourId:""
    property string role:"foreground"
    property color fallback:Theme.accent
    property bool shared:false
    property bool sidebar:false
    property bool sidebarText:false
    readonly property string stored:shared?(SettingsService.moduleColourSync[role]||""):sidebar?(sidebarText?SettingsService.sidebarTextColours[colourId]:SettingsService.sidebarColours[colourId])||"":SettingsService.shellColours[colourId]?.[role]||""
    readonly property string mode:stored==="accent"?"accent":stored==="wallpaper"?"wallpaper":stored.startsWith("#")?"hex":"default"
    function save(value):void {if(shared){SettingsService.setSharedModuleColour(role,value);}else if(sidebar){if(sidebarText)SettingsService.setSidebarTextColour(colourId,value);else SettingsService.setSidebarColour(colourId,value);}else SettingsService.setShellColour(colourId,role,value)}
    Dialogs.ColorDialog {id:picker;title:root.label;onAccepted:root.save(String(selectedColor))}
    RowLayout {
        spacing:7
        ThemedComboBox {implicitWidth:132;model:[{id:"default",name:Tr.t("Default")},{id:"accent",name:Tr.t("Theme accent")},{id:"wallpaper",name:Tr.t("Wallpaper")},{id:"hex",name:Tr.t("Hex")}];textRole:"name";currentIndex:Math.max(0,model.findIndex(m=>m.id===root.mode));onActivated:index=>root.save(model[index].id==="default"?"":model[index].id==="accent"?"accent":model[index].id==="wallpaper"?"wallpaper":String(root.fallback))}
        Rectangle {implicitWidth:32;implicitHeight:32;radius:7;color:root.mode==="hex"?root.stored:root.mode==="accent"?Theme.accent:root.mode==="wallpaper"?ThemeService.dynamicColors?.accent||Theme.accent:root.fallback;border.width:1;border.color:Theme.borderIn(QsWindow.window)
            MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{picker.selectedColor=root.mode==="hex"?root.stored:root.fallback;picker.open()}}
        }
        Rectangle {
            visible:root.mode==="hex";implicitWidth:112;implicitHeight:32;radius:7
            color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:hex.activeFocus?Theme.accentIn(QsWindow.window):Theme.borderIn(QsWindow.window)
            TextInput {
                id:hex;anchors.fill:parent;anchors.leftMargin:8;anchors.rightMargin:8
                text:root.stored;verticalAlignment:TextInput.AlignVCenter;selectByMouse:true
                font.family:Theme.fontMono;font.pixelSize:12;color:Theme.textIn(QsWindow.window)
                validator:RegularExpressionValidator {regularExpression:/#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?/}
                onEditingFinished:if(acceptableInput)root.save(text)
            }
        }
    }
}
