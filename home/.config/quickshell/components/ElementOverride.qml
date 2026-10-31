import QtQuick
import "../services"
QtObject {
    id:root
    property Item target
    property string moduleId:""
    property string elementKey:""
    property var originalTransforms:[]
    property var designSource:null
    readonly property var design:designSource!==null?designSource:(SettingsService.moduleElements||{})[moduleId]?.[elementKey]||({})
    readonly property Translate shift:Translate{x:root.design.x??0;y:root.design.y??0}
    readonly property Scale sizing:Scale{xScale:(root.design.widthScale??100)/100;yScale:(root.design.heightScale??100)/100}
    readonly property Binding colour:Binding{
        target:root.target && "color" in root.target?root.target:null
        property:"color";value:root.design.color??"transparent";when:root.design.color!==undefined
        restoreMode:Binding.RestoreBindingOrValue
    }
    readonly property Binding textSize:Binding{
        target:root.target && "font" in root.target?root.target:null
        property:"font.pixelSize";value:root.design.fontSize??14;when:root.design.fontSize!==undefined
        restoreMode:Binding.RestoreBindingOrValue
    }
    readonly property Binding textFamily:Binding{
        target:root.target && "font" in root.target?root.target:null
        property:"font.family";value:root.design.fontFamily??"";when:Boolean(root.design.fontFamily)
        restoreMode:Binding.RestoreBindingOrValue
    }
    readonly property Binding alpha:Binding{target:root.target;property:"opacity";value:(root.design.opacity??100)/100;when:root.design.opacity!==undefined;restoreMode:Binding.RestoreBindingOrValue}
    Component.onCompleted:{
        if(!target)return
        const list=[];for(let i=0;i<target.transform.length;i++)list.push(target.transform[i])
        originalTransforms=list;target.transform=list.concat([sizing,shift])
    }
    Component.onDestruction:if(target)target.transform=originalTransforms
}
