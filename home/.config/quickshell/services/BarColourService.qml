pragma Singleton
import QtQuick
QtObject {
    id:root
    readonly property var designs:[
        {id:"black",name:"Black/grey · Black",description:"Solid black across the bar and modules.",values:{surfaceStyle:"classic",floatingBarSurface:"black"}},
        {id:"grey",name:"Black/grey · Grey",description:"Soft dark grey across the bar and modules.",values:{surfaceStyle:"classic",floatingBarSurface:"grey"}},
        {id:"glass",name:"Glass",description:"Wallpaper-tinted glass with background blur.",values:{surfaceStyle:"glass"}},
        {id:"liquid",name:"Liquid Glass",description:"The current refractive glass material.",values:{surfaceStyle:"liquid"}},
        {id:"tahoe",name:"MacShell Liquid Glass",description:"Curved refraction, soft blur and a clear white rim. No rainbow splitting.",values:{surfaceStyle:"tahoe"}},
        {id:"liquid-old",name:"Liquid Glass (Old)",description:"The original frosted liquid glass material.",values:{surfaceStyle:"liquid-old"}}
    ]
    function matches(values:var):bool {
        return SettingsService.surfaceStyle===values.surfaceStyle && (values.surfaceStyle!=="classic" || SettingsService.floatingBarSurface===values.floatingBarSurface)
    }
    function apply(values:var):void {
        if(!SettingsService.arrived)return
        if(values.floatingBarSurface)SettingsService.set("floatingBarSurface",values.floatingBarSurface)
        SettingsService.set("surfaceStyle",values.surfaceStyle)
        SettingsService.set("desktopGround",values.surfaceStyle)
        SettingsService.set("dockGround",values.surfaceStyle)
        // A launcher-specific solid colour would hide the selected glass.
        SettingsService.set("launcherStyle",Object.assign({},SettingsService.launcherStyle,{surfaceTone:"theme"}))
    }
}
