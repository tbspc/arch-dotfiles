import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import Quickshell
import "../theme"
import "../services"
import "../components"
SettingGroup {
    id:root
    property string name:""
    property bool editing:false
    property bool linkWallpaper:true
    property var palette:({})
    property string pickingKey:"accent"
    Component.onCompleted:if(root.editing)root.copyCurrent()
    readonly property var colourFields:[{id:"accent",name:"Accent"},{id:"accentHover",name:"Accent hover"},{id:"accentText",name:"Text on accent"},{id:"background",name:"Background"},{id:"surface",name:"Surfaces"},{id:"surfaceHover",name:"Hover surfaces"},{id:"border",name:"Borders"},{id:"text",name:"Main text"},{id:"textMuted",name:"Secondary text"},{id:"red",name:"Error / red"},{id:"green",name:"Success / green"},{id:"yellow",name:"Warning / yellow"},{id:"blue",name:"Blue"}]
    function copyCurrent():void {const p={};for(const key of Theme.tokens)p[key]=String(Theme[key==="textMuted"?"paletteMuted":key]);root.palette=p}
    function setColour(key:string,value:string):void {if(/^#[0-9a-fA-F]{6}$/.test(value))root.palette=Object.assign({},root.palette,{[key]:value})}
    Dialogs.ColorDialog {id:picker;title:Tr.t("Choose theme colour");onAccepted:root.setColour(root.pickingKey,String(selectedColor))}

    title:Tr.t("Saved colour themes")
    note:Tr.t("Save the full palette, app colours, glass material, module colours and sidebar colours together.")
    SettingRow {label:Tr.t("Build your own theme");reading:Tr.t("Edit hex values or choose colours, including text. Module overrides are saved with the theme.");PillButton {text:root.editing?Tr.t("Hide editor"):Tr.t("Edit colours");onClicked:{if(!root.editing)root.copyCurrent();root.editing=!root.editing}}}
    Repeater {model:root.editing?root.colourFields:[]
        SettingRow {
            required property var modelData
            label:Tr.t(modelData.name)
            RowLayout {spacing:8
                Rectangle {implicitWidth:32;implicitHeight:32;radius:7;color:root.palette[modelData.id]||"#000000";border.width:1;border.color:Theme.borderIn(QsWindow.window)
                    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{root.pickingKey=modelData.id;picker.selectedColor=root.palette[modelData.id];picker.open()}}
                }
                Rectangle {implicitWidth:120;implicitHeight:34;radius:7;color:Theme.surfaceIn(QsWindow.window);border.width:1;border.color:hex.activeFocus?Theme.accentIn(QsWindow.window):Theme.borderIn(QsWindow.window)
                    TextInput {id:hex;anchors.fill:parent;anchors.leftMargin:10;verticalAlignment:TextInput.AlignVCenter;selectByMouse:true;text:root.palette[modelData.id]||"";font.family:Theme.fontMono;font.pixelSize:12;color:Theme.textIn(QsWindow.window);validator:RegularExpressionValidator {regularExpression:/#[0-9a-fA-F]{6}/} onEditingFinished:if(acceptableInput)root.setColour(modelData.id,text)}
                }
            }
        }
    }
    SettingRow {visible:root.editing;label:Tr.t("Start from active theme");PillButton {text:Tr.t("Reload colours");onClicked:root.copyCurrent()}}
    Loader {active:root.editing;Layout.fillWidth:true;sourceComponent:Component {ModuleColoursSection {}}}
    SettingRow {label:Tr.t("Link current wallpaper");reading:Tr.t("Selecting the saved theme restores this wallpaper");ToggleSwitch {checked:root.linkWallpaper;onToggled:value=>root.linkWallpaper=value}}
    SettingField {label:Tr.t("Theme name");value:root.name;placeholder:Tr.t("My colour theme");onEdited:value=>root.name=value}
    SettingRow {label:ThemeService.colourThemeMessage||Tr.t("Save every current colour");PillButton {text:root.editing?Tr.t("Save and apply"):Tr.t("Save theme");onClicked:{const id=ThemeService.saveColourTheme(root.name,root.editing?root.palette:null,root.linkWallpaper?WallpaperService.chosen:"");if(root.editing&&id)ThemeService.setTheme(id);root.name=""}}}
    Repeater {model:SettingsService.savedColourThemes
        SettingRow {required property var modelData;label:modelData.name
            Row {spacing:8;PillButton {text:Tr.t("Apply");onClicked:ThemeService.setTheme(modelData.id)} PillButton {text:Tr.t("Delete");onClicked:ThemeService.deleteColourTheme(modelData.id)}}
        }
    }
}
