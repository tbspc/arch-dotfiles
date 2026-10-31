import QtQuick
import "../services"
Item {
    id:root
    visible:false
    property Item target:null
    property string moduleId:""
    property var bindings:[]
    property var overrideValues:null
    property int retries:0
    function scan():void {
        if(!target)return
        const designs=overrideValues!==null?overrideValues:(SettingsService.moduleElements||{})[moduleId]||{}
        const alive=[]
        for(const helper of bindings){if(helper.target)alive.push(helper);else helper.destroy()}
        if(alive.length!==bindings.length)bindings=alive
        const keys=Object.keys(designs)
        if(!keys.length || keys.every(key=>bindings.some(b=>b.target && b.elementKey===key)))return
        for(const item of ModuleService.designElements(target)) {
            const key=ModuleService.elementKey(item)
            if(item.designManaged===true || !designs[key] || bindings.some(b=>b.target===item))continue
            const helper=overrideComponent.createObject(root,{target:item,moduleId:root.moduleId,elementKey:key,designSource:Qt.binding(()=>root.overrideValues!==null?root.overrideValues[key]||{}:null)})
            if(helper)bindings=bindings.concat([helper])
        }
    }
    function schedule():void{retries=0;if(later)later.restart()}
    onOverrideValuesChanged:schedule()
    function rebuild():void{for(const helper of bindings)if(helper)helper.destroy();bindings=[];if(later)later.restart()}
    onTargetChanged:rebuild()
    onModuleIdChanged:rebuild()
    Component.onCompleted:later.restart()
    Timer{id:later;interval:16;onTriggered:{root.scan();if(root.retries++<3)later.restart()}}
    Connections{target:SettingsService;function onModuleElementsChanged(){root.scan()}}
    Connections{target:root.target;function onChildrenChanged(){later.restart()}}
    Connections{target:MediaService;function onPlayingChanged(){root.schedule()}}
    Connections{target:ModuleService;function onActivitiesChanged(){root.schedule()}}
    Component{id:overrideComponent;ElementOverride{}}
}
