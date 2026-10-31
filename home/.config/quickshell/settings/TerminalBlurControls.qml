import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import "../theme"
import "../services"
import "../components"
SettingGroup {
    id: root
    property string settingKey:"terminalFrost"
    property string applicationName:Tr.t("Terminal")
    readonly property var values:SettingsService[root.settingKey]||{}
    title: Tr.t("Blur & frost")
    note: root.applicationName+Tr.t(" background only. Text and icons stay sharp and opaque.")
    function change(key:string,value:var):void {SettingsService.set(root.settingKey,Object.assign({},root.values,{[key]:value}))}
    Repeater {
        model: [
            {key:"opacity",label:"Background opacity",from:5,to:95,unit:"%",fallback:35},
            {key:"frost",label:"Frostiness",from:0,to:100,unit:"%",fallback:50},
            {key:"passes",label:"Blur passes",from:1,to:4,unit:"",fallback:2},
            {key:"grain",label:"Grain",from:0,to:25,unit:"%",fallback:4},
            {key:"saturation",label:"Saturation",from:0,to:200,unit:"%",fallback:100},
            {key:"brightness",label:"Brightness",from:50,to:150,unit:"%",fallback:100},
            {key:"contrast",label:"Contrast",from:50,to:150,unit:"%",fallback:100},
            {key:"tint",label:"Tint strength",from:0,to:100,unit:"%",fallback:8}
        ]
        delegate: SettingSlider {
            required property var modelData
            label:Tr.t(modelData.label);from:modelData.from;to:modelData.to;unit:modelData.unit
            value:root.values[modelData.key] ?? modelData.fallback
            onMoved:value=>root.change(modelData.key,Math.round(value))
        }
    }
    SettingRow {
        label:Tr.t("Tint colour")
        RowLayout {
            Rectangle {width:30;height:30;radius:8;color:root.values.tintColor||"#ffffff";border.color:Theme.border
                MouseArea {anchors.fill:parent;onClicked:tintPicker.open()}}
            TextInput {text:root.values.tintColor||"#ffffff";color:Theme.text;font.pixelSize:13;selectByMouse:true
                validator:RegularExpressionValidator {regularExpression:/#[0-9a-fA-F]{6}/}
                onEditingFinished:if(acceptableInput)root.change("tintColor",text)}
        }
    }
    ColorDialog {id:tintPicker;selectedColor:root.values.tintColor||"#ffffff";onAccepted:root.change("tintColor",selectedColor.toString().slice(0,7))}
}
