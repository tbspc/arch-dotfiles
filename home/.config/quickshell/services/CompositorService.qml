// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   C O M P O S I T O R   S E R V I C E                                    │
// │   hyprland options, for this session                                     │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import "../theme"

// Hyprland options set from the settings window.
//
// Nothing here writes to `hypr/*.lua`: rewriting a user-edited file would
// fight their edits and drop their comments. Changed options are kept in the
// shell's settings and pushed with `hyprctl` at startup and after every
// `configreloaded`. Options never touched are absent from the store, so the
// Lua config still decides them.
Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/compositor.py")

    property var options: ({})
    property bool loaded: false

    function value(option: string, fallback: var): var {
        const current = root.options[option]
        return (current === undefined || current === null) ? fallback : current
    }

    readonly property Process reader: Process {
        command: [root.script, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return
                try {
                    root.options = JSON.parse(text)
                    root.loaded = true
                } catch (error) {
                    console.warn("Cannot parse the compositor options:", error)
                }
            }
        }
    }

    readonly property Process writer: Process {
        onExited: root.load()
    }

    function load(): void {
        root.reader.running = true
    }

    function set(option: string, value: var): void {
        root.writer.command = [root.script, "set", option, String(value)]
        root.writer.running = true
    }

    // ── STORE ───────────────────────────────────────────────────────────────
    //
    // `SettingsService.compositor`: option path → value, absent if untouched.
    // `compositor.py` owns the whitelist and rejects anything else, which
    // also keeps slider values from turning into arbitrary `hyprctl eval`.

    // A property, so the push fires when the store changes: on the first
    // load of the settings file and after every change.
    readonly property var store: SettingsService.compositor

    onStoreChanged: root.pushSoon.restart()

    // The keyboard's options are a machine setting, so a profile switch keeps
    // them; they are pushed after the profile's store and win over it.
    readonly property var keyboardOptions: [
        "input:kb_layout", "input:kb_variant", "input:kb_model",
        "input:kb_options", "input:kb_rules"
    ]
    readonly property var keyboard: SettingsService.keyboard

    onKeyboardChanged: root.pushSoon.restart()

    // Sliders report every step; debounce so a drag is one push.
    readonly property Timer pushSoon: Timer {
        interval: 120
        onTriggered: root.applyStore()
    }

    function applyStore(): void {
        const kept = Object.assign({}, root.store ?? ({}), root.keyboard ?? ({}))
        if (SettingsService.gameMode)
            kept["decoration:blur:enabled"] = "false"
        if (Object.keys(kept).length === 0) {
            root.load()
            return
        }
        root.applier.command = [root.script, "apply", JSON.stringify(kept)]
        root.applier.running = true
    }

    readonly property Process applier: Process {
        onExited: root.load()
    }

    // Controls only write the store; the push follows from the store change,
    // so live changes and reloads share one path.
    function remember(option: string, value: var): void {
        const key = root.keyboardOptions.indexOf(option) >= 0 ? "keyboard" : "compositor"
        const next = Object.assign({}, (key === "keyboard" ? root.keyboard : root.store) ?? ({}))
        next[option] = String(value)
        SettingsService.set(key, next)
    }

    // Emptying the store doesn't undo what Hyprland already holds, so the
    // config is reloaded to restore its own values.
    function restoreDefaults(): void {
        SettingsService.set("compositor", ({}))
        root.reloader.running = true
    }

    // After a profile switch Hyprland still holds the previous profile's
    // values, including options the new one never sets. A reload clears them,
    // and the reload handler pushes everything again (`reloads`).
    function reassert(): void {
        root.reloader.running = true
    }

    readonly property Process reloader: Process {
        command: ["hyprctl", "reload"]
        onExited: root.load()
    }

    // ── LAYOUT ──────────────────────────────────────────────────────────────
    //
    // How tiled windows are placed, for every workspace at once. It rides the
    // store like any other option; the key cycles it and says which it chose.
    readonly property var windowLayouts: [
        { id: "dwindle",   label: "Dwindle",   icon: "󰕴" },
        { id: "master",    label: "Master",    icon: "󰛾" },
        { id: "scrolling", label: "Scrolling", icon: "󰕬" }
    ]

    // The store first: Hyprland's answer lags a push, and a quick second
    // press would cycle from the old value.
    readonly property string windowLayout:
        root.store?.["general:layout"] ?? root.value("general:layout", "dwindle")

    function cycleLayout(): void {
        const ids = root.windowLayouts.map(entry => entry.id)
        const next = root.windowLayouts[(ids.indexOf(root.windowLayout) + 1) % ids.length]
        root.remember("general:layout", next.id)
        OsdService.requested(next.icon, `${Tr.t("Layout")} · ${Tr.t(next.label)}`, -1)
    }

    // ── GAME MODE ───────────────────────────────────────────────────────────
    //
    // No animations, blur, shadow or glass, each push reading it over its own
    // setting. Turning it off reloads instead: blur nobody has set lives in
    // look.lua, and only a reload reads it back.
    readonly property bool gameMode: SettingsService.gameMode

    onGameModeChanged: {
        if (!root.gameMode) {
            root.reloader.running = true
            return
        }
        root.applyAnimations()
        root.applyShadow()
        root.applyGlass()
        root.applyGround()
        root.applyStore()
    }

    readonly property string nautilusWindowMode:SettingsService.nautilusWindowMode
    onNautilusWindowModeChanged:root.applyNautilusWindowMode()
    function applyNautilusWindowMode():void {root.nautilusWindowUpdate.restart()}
    readonly property Connections nautilusModeArrival:Connections {
        target:SettingsService
        function onArrivedChanged():void {if(SettingsService.arrived)root.applyNautilusWindowMode()}
    }
    readonly property Timer nautilusWindowUpdate:Timer {
        interval:16
        onTriggered:{
            if(!SettingsService.arrived)return
            if(root.nautilusWindowSetter.running){restart();return}
            const floating=SettingsService.nautilusWindowMode==="floating"
            root.nautilusWindowSetter.command=["hyprctl","eval",`
                _G.impastoNautilusModeRule=hl.window_rule({name="impasto-nautilus-window-mode",match={class="^(org[.]gnome[.]Nautilus)$"},float=${floating}})
                for _,w in ipairs(hl.get_windows()) do
                    if w.class=="org.gnome.Nautilus" and w.floating~=${floating} then
                        hl.dispatch(hl.dsp.window.float({window=w,action="toggle"}))
                    end
                end`]
            root.nautilusWindowSetter.running=true
        }
    }
    readonly property Process nautilusWindowSetter:Process {}

    function applySettingsWindowMode():void {
        root.settingsWindowUpdate.restart()
    }
    readonly property string settingsWindowMode:SettingsService.settingsWindowMode
    onSettingsWindowModeChanged:root.applySettingsWindowMode()
    readonly property Timer settingsWindowUpdate:Timer {
        interval:16
        onTriggered:{
            if(root.settingsWindowSetter.running){restart();return}
            const floating=SettingsService.settingsWindowMode!=="tiled"
            root.settingsWindowSetter.command=["hyprctl","eval",`if _G.impastoSettingsRule then _G.impastoSettingsRule:set_enabled(${floating}) end; for _,w in ipairs(hl.get_windows()) do if (w.class=="org.quickshell" or w.class=="quickshell") and w.title=="Hyprland Settings" and w.floating~=${floating} then hl.dispatch(hl.dsp.window.float({window=w,action="toggle"})) end end`]
            root.settingsWindowSetter.running=true
        }
    }
    readonly property Process settingsWindowSetter:Process {}
    function refreshBarGlass():void {
        if(root.liquidLayerWanted())root.glassRefreshDelay.restart()
    }
    readonly property Timer glassRefreshDelay:Timer {
        interval:16
        onTriggered:{if(root.glassRefresher.running){restart();return}root.glassRefresher.running=true}
    }
    readonly property Process glassRefresher:Process {command:["hyprctl","hyprglass","refresh"]}
    readonly property Timer glassSettledRefresh:Timer {interval:Math.max(400,Math.round(65000/Math.max(25,SettingsService.windowAnimationSpeed)));onTriggered:root.refreshBarGlass()}
    function refreshRevealedGlass():void {root.refreshBarGlass();root.glassSettledRefresh.restart()}

    // ── ANIMATIONS ──────────────────────────────────────────────────────────
    //
    // `animations.lua` only enables animations; the preset is pushed from
    // here. One `hyprctl eval` for the whole preset rather than one per leaf,
    // so no window animates on a mix of old and new curves.
    function applyAnimations(): void {
        root.animator.command = ["hyprctl", "eval",
            Motion.chunk(SettingsService.gameMode ? "off" : SettingsService.animationPreset)]
        root.animator.running = true
    }

    readonly property Process animator: Process {}

    onAnimationPresetChanged: root.applyAnimations()
    readonly property string animationOptions:`${SettingsService.windowAnimationSpeed}:${SettingsService.windowAnimationAmount}:${SettingsService.windowAnimationBounce}:${SettingsService.windowWorkspaceMotion}:${JSON.stringify(SettingsService.windowMotion)}`
    onAnimationOptionsChanged:animationUpdate.restart()
    readonly property Timer animationUpdate:Timer {interval:25;onTriggered:{if(root.animator.running)restart();else root.applyAnimations()}}


    // ── SHADOW ──────────────────────────────────────────────────────────────
    //
    // Off in `look.lua`; enabled from here. Range and opacity come from
    // `Theme`, so windows and bar capsules cast the same shadow. `render_power`
    // shapes Hyprland's falloff and has no counterpart in the bar's Gaussian.
    //
    // hyprglass renders through the shadow decoration, and this chunk is
    // re-pushed after every reload, so disabling the shadow would also
    // disable the glass. While glass is on, the decoration stays enabled but
    // invisible (range 0, alpha 0).
    function shadowChunk(): string {
        const drawn = SettingsService.windowShadow && !SettingsService.gameMode
        const alpha = drawn ? Math.round(Theme.windowShadowOpacity * 255)
                                  .toString(16).padStart(2, "0") : "00"
        const tint=SettingsService.windowShadowUseAccent?Theme.accent:Qt.rgba(0,0,0,1)
        const rgb=[tint.r,tint.g,tint.b].map(v=>Math.round(v*255).toString(16).padStart(2,"0")).join("")
        return `hl.config({ decoration = { shadow = { `
             + `enabled = ${drawn || root.glassOn() || SettingsService.macGlassSettings || SettingsService.macGlassTerminal || SettingsService.terminalGround === "blur" || SettingsService.nautilusBlur || SettingsService.settingsBlur || SettingsService.macGlassWindows || SettingsService.macGlassNautilus || SettingsService.macGlassFileDialogs || root.liquidLayerWanted()}, `
             + `range = ${drawn ? Theme.windowShadowRange : 0}, render_power = ${SettingsService.windowShadowSharpness}, offset = {${SettingsService.windowShadowOffsetX},${SettingsService.windowShadowOffsetY}}, `
             + `color = "rgba(${rgb}${alpha})" } } })`
    }

    function applyShadow(): void {
        root.shadowUpdate.restart()
    }

    // Coalesce slider motion and retry if an earlier compositor push is
    // still running, ensuring the final slider value always reaches Hyprland.
    readonly property Timer shadowUpdate: Timer {
        interval: 25
        onTriggered: {
            if (root.shadower.running) {
                restart()
                return
            }
            root.shadower.command = ["hyprctl", "eval", root.shadowChunk()]
            root.shadower.running = true
        }
    }

    readonly property Process shadower: Process {}

    // Mirrored locally so a change triggers a push.
    readonly property bool windowShadow: SettingsService.windowShadow

    onWindowShadowChanged: root.applyShadow()
    readonly property int windowShadowRange: SettingsService.windowShadowRange
    readonly property int windowShadowIntensity: SettingsService.windowShadowIntensity
    onWindowShadowRangeChanged: root.applyShadow()
    onWindowShadowIntensityChanged: root.applyShadow()
    readonly property string shadowOptions:`${SettingsService.windowShadowSharpness}:${SettingsService.windowShadowOffsetX}:${SettingsService.windowShadowOffsetY}:${SettingsService.windowShadowUseAccent}:${String(Theme.accent)}:${SettingsService.macGlassWindows}:${SettingsService.macGlassTerminal}:${SettingsService.macGlassSettings}:${SettingsService.macGlassNautilus}:${SettingsService.macGlassFileDialogs}:${SettingsService.macGlassFileDialogOpacity}:${SettingsService.terminalGround}:${SettingsService.macGlassBlur}:${SettingsService.macGlassRefraction}:${SettingsService.macGlassTint}:${SettingsService.macGlassShine}:${SettingsService.macGlassRefractionMode}:${SettingsService.macGlassEdgeWidth}:${SettingsService.macGlassSpread}:${SettingsService.macGlassCentreStrength}:${SettingsService.macGlassFlow}:${Theme.capsuleHeight}:${JSON.stringify(SettingsService.macGlassBarProfile)}`
    onShadowOptionsChanged:root.applyShadow()


    readonly property string animationPreset: SettingsService.animationPreset

    // A reload drops everything pushed at runtime; push it all again.
    readonly property Connections reloads: Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "configreloaded") {
                if(!root.glassBootstrap.running)root.glassBootstrap.running=true
                root.applyNautilusWindowMode()
                root.applySettingsWindowMode()
                root.applyAnimations()
                root.applyShadow()
                root.applyStore()
                root.applyCursor()
                root.applyShake()
                root.applyGlass()
                root.applyGround()
            }
        }
    }

    Component.onCompleted: {
        root.applyNautilusWindowMode()
        root.applyAnimations()
        root.applyShadow()
        // The settings file loads asynchronously, so the store is usually
        // still empty here and `onStoreChanged` does the real push; this
        // still reads the compositor's current values once.
        root.applyStore()
        // A shell-only restart fires no reload, so push plugin settings here.
        root.applyShake()
        root.applyGlass()
        root.applyGround()
    }

    // ── KEYBOARD LAYOUTS ────────────────────────────────────────────────────
    //
    // Every layout in the xkb rules list. Loaded on demand: only the input
    // page needs it, and the file is ~47 KB.
    property var layouts: []

    function loadLayouts(): void {
        if (root.layouts.length === 0)
            root.layoutReader.running = true
    }

    readonly property Process layoutReader: Process {
        command: [root.script, "layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "")
                    return
                try {
                    root.layouts = JSON.parse(text)
                } catch (error) {
                    console.warn("Cannot parse the keyboard layouts:", error)
                }
            }
        }
    }

    function labelForLayout(id: string): string {
        const found = root.layouts.find(entry => entry.id === id)
        return found ? found.label : id
    }

    // xkb group-switch options, passed through by Hyprland. Without one, a
    // second layout is loaded but unreachable.
    readonly property var layoutSwitches: [
        { id: "", label: "None" },
        { id: "grp:alt_shift_toggle", label: "Alt + Shift" },
        { id: "grp:win_space_toggle", label: "Super + Space" },
        { id: "grp:caps_toggle", label: "Caps Lock" }
    ]

    // ── CURSOR ──────────────────────────────────────────────────────────────
    //
    // One vector cursor, recoloured and compiled by compositor.py and set with
    // `hyprctl setcursor`, which reaches clients as well as the compositor.
    // "palette" tracks the accent; anything else is a fixed `#rrggbb`.
    readonly property string cursorHex:
        SettingsService.cursorColor === "palette"
            ? String(Theme.accent) : SettingsService.cursorColor

    function applyCursor(): void {
        root.cursorSetter.command = ["python", Quickshell.shellPath("scripts/cursor_style.py"),
            SettingsService.cursorStyle, String(SettingsService.cursorSize)]
        root.cursorSetter.running = true
    }

    readonly property Process cursorSetter: Process {}

    // The accent animates over `paletteTransition`; wait for it to settle
    // instead of recompiling the cursor on every frame.
    readonly property Timer cursorDebounce: Timer {
        interval: 450
        onTriggered: root.applyCursor()
    }

    // Includes the accent, so a palette change re-fires it.
    readonly property string cursorChoice:
        `${SettingsService.cursorStyle}:${SettingsService.cursorSize}`

        onCursorChoiceChanged: root.cursorDebounce.restart()


            // Keep Hyprland's window borders in step with the active wallpaper palette.
    readonly property string borderChoice:
        `${String(Theme.accent)}:${String(Theme.textMuted)}`

    onBorderChoiceChanged: root.borderDebounce.restart()

    readonly property Timer borderDebounce: Timer {
        interval: 450
        onTriggered: root.applyBorders()
    }

    function applyBorders(): void {
        const active = JSON.stringify(String(Theme.accent))
        const inactive = JSON.stringify(String(Theme.textMuted))
        root.borderSetter.command = [
            "hyprctl", "eval",
            `hl.config({ general = { col = { active_border = ${active}, inactive_border = ${inactive} } } })`
        ]
        root.borderSetter.running = true
    }

    readonly property Process borderSetter: Process {
        Component.onCompleted: root.applyBorders()
    }




    // ── SHAKE TO FIND ─────────────────────────────────────────────────────────
    //
    // hypr-dynamic-cursors' `shake.enabled`. `input.lua` turns it on, so it
    // is pushed on change and after every reload. `shakeAvailable` dims the
    // settings toggle when the plugin isn't loaded.
    property bool shakeAvailable: false

    function loadShake(): void {
        root.shakeReader.running = true
    }

    readonly property Process shakeReader: Process {
        command: [root.script, "available", "plugin:dynamic_cursors:shake:enabled"]
        stdout: StdioCollector {
            onStreamFinished: root.shakeAvailable = text.trim() === "true"
        }
    }

    function applyShake(): void {
        root.shakeSetter.command = ["hyprctl", "eval",
            `hl.config({ plugin = { dynamic_cursors = { shake = { enabled = ${
                SettingsService.shakeToFind ? "true" : "false"} } } } })`]
        root.shakeSetter.running = true
    }

    readonly property Process shakeSetter: Process {}

    onShakeToFindChanged: root.applyShake()

    readonly property bool shakeToFind: SettingsService.shakeToFind


    // ── GLASS ───────────────────────────────────────────────────────────────
    //
    // hyprglass `enabled`: off in `look.lua`, pushed on change and after
    // every reload. The chunk carries its own `hl.plugin.hyprglass` guard,
    // since that table doesn't exist until the plugin loads; the eval is a
    // no-op without the plugin and on the parse before it loads.
    property bool glassAvailable: false

    function loadGlass(): void {
        root.glassReader.running = true
    }

    readonly property Process glassReader: Process {
        command: [root.script, "available", "plugin:hyprglass:enabled"]
        stdout: StdioCollector {
            onStreamFinished: root.glassAvailable = text.trim() === "true"
        }
    }

    function applyGlass(): void {
        if(root.glassBootstrap.running){root.glassUpdatePending=true;return}
        if(root.glassSetter.running){root.glassUpdatePending=true;return}
        root.glassUpdatePending=false
        root.glassSetter.command = ["hyprctl", "eval", root.macGlassChunk()]
        root.glassSetter.running = true
    }

    property bool glassUpdatePending:false
    readonly property Process glassSetter: Process {onExited:if(root.glassUpdatePending)root.applyGlass();stdout:StdioCollector {onStreamFinished:if(text.trim() && text.trim()!=="ok")console.warn("MacShell window glass:",text.trim())}}

    // Window values and named layer profiles update independently at runtime.
    property var nativeGlassBefore:({})
    readonly property FileView nativeGlassBackup:FileView {
        path:SettingsService.stateDirectory+"/macshell-native-before.json";printErrors:false
        onLoaded:{try{root.nativeGlassBefore=JSON.parse(text())}catch(error){}}
    }
    function luaGlass(value:var):string {
        if(value!==null && typeof value==="object")return "{"+Object.keys(value).map(key=>key+"="+root.luaGlass(value[key])).join(",")+"}"
        return JSON.stringify(value)
    }
    function macGlassChunk():string {
        const enabled=!SettingsService.gameMode
        const windows=enabled&&SettingsService.macGlassWindows
        const dialogs=enabled&&(SettingsService.macGlassFileDialogs||SettingsService.macGlassWindows)
        const dialogOpacity="1.00"
        const frostFiles=enabled&&SettingsService.nautilusBlur
        const frostSettings=enabled&&SettingsService.settingsBlur
        const settingsWanted=enabled&&(SettingsService.settingsBlur||SettingsService.macGlassSettings)
        const files=enabled&&(SettingsService.nautilusBlur||SettingsService.macGlassNautilus||SettingsService.macGlassWindows)
        const frostTerminal=enabled&&SettingsService.terminalGround==="blur"
        const terminal=enabled&&!frostTerminal&&(SettingsService.macGlassTerminal||SettingsService.terminalGround==="tahoe")
        return `if not _G.impastoFileGlassEnvironment then
            hl.env("GTK_MODULES","impasto-file-glass")
            hl.env("GTK_PATH",${JSON.stringify(Quickshell.env("HOME")+"/.local/lib/impasto-gtk")})
            _G.impastoFileGlassEnvironment=true
        end
        if hl.plugin.hyprglass ~= nil then
            local hg=hl.plugin.hyprglass
            hg.config(${root.luaGlass(root.macGlassValues())})
            hg.preset("impasto_tahoe_bar",${root.luaGlass(root.macGlassLayerValues())})
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_windows_enable:set_enabled(${windows?"true":"false"}) end
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_windows_preset:set_enabled(${windows?"true":"false"}) end
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_terminal_enable:set_enabled(${terminal?"true":"false"}) end
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_terminal_preset:set_enabled(${terminal?"true":"false"}) end
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_shell_no_double:set_enabled(false) end
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_settings_enable:set_enabled(${settingsWanted&&!frostSettings?"true":"false"}) end
            if _G.impastoMacGlassRules then _G.impastoMacGlassRules.impasto_tahoe_settings_preset:set_enabled(${settingsWanted&&!frostSettings?"true":"false"}) end
            _G.impastoMacGlassRules=_G.impastoMacGlassRules or {}
            local rules=_G.impastoMacGlassRules
            hg.preset("impasto_blur_nautilus",${root.luaGlass(root.blurValues(SettingsService.nautilusFrost))})
            hg.preset("impasto_blur_settings",${root.luaGlass(root.blurValues(SettingsService.settingsFrost))})
            if not rules.impasto_blur_nautilus_enable then
                rules.impasto_blur_nautilus_enable=hl.window_rule({name="impasto-blur-nautilus-enable",match={class="^(org[.]gnome[.]Nautilus)$"},tag="+hyprglass_enabled"})
                rules.impasto_blur_nautilus_preset=hl.window_rule({name="impasto-blur-nautilus-preset",match={class="^(org[.]gnome[.]Nautilus)$"},tag="+hyprglass_preset_impasto_blur_nautilus"})
                rules.impasto_blur_settings_enable=hl.window_rule({name="impasto-blur-settings-enable",match={class="^(org.quickshell|quickshell)$",title="^(Hyprland Settings)$"},tag="+hyprglass_enabled"})
                rules.impasto_blur_settings_preset=hl.window_rule({name="impasto-blur-settings-preset",match={class="^(org.quickshell|quickshell)$",title="^(Hyprland Settings)$"},tag="+hyprglass_preset_impasto_blur_settings"})
            end
            rules.impasto_blur_nautilus_enable:set_enabled(${frostFiles?"true":"false"})
            rules.impasto_blur_nautilus_preset:set_enabled(${frostFiles?"true":"false"})
            rules.impasto_blur_settings_enable:set_enabled(${frostSettings?"true":"false"})
            rules.impasto_blur_settings_preset:set_enabled(${frostSettings?"true":"false"})
            hg.preset("impasto_terminal_blur",${root.luaGlass(root.terminalBlurValues())})
            if not rules.impasto_terminal_blur_enable then
                rules.impasto_terminal_blur_enable=hl.window_rule({name="impasto-terminal-blur-enable",match={class="^(kitty)$"},tag="+hyprglass_enabled"})
                rules.impasto_terminal_blur_preset=hl.window_rule({name="impasto-terminal-blur-preset",match={class="^(kitty)$"},tag="+hyprglass_preset_impasto_terminal_blur"})
            end
            rules.impasto_terminal_blur_enable:set_enabled(${frostTerminal?"true":"false"})
            rules.impasto_terminal_blur_preset:set_enabled(${frostTerminal?"true":"false"})
            if not rules.impasto_tahoe_nautilus_enable then
                rules.impasto_tahoe_nautilus_enable=hl.window_rule({name="impasto-tahoe-nautilus-enable",match={class="^(org[.]gnome[.]Nautilus)$"},tag="+hyprglass_enabled"})
                rules.impasto_tahoe_nautilus_preset=hl.window_rule({name="impasto-tahoe-nautilus-preset",match={class="^(org[.]gnome[.]Nautilus)$"},tag="+hyprglass_preset_impasto_tahoe"})
            end
            if not rules.impasto_tahoe_nautilus_disable then
                rules.impasto_tahoe_nautilus_disable=hl.window_rule({name="impasto-tahoe-nautilus-disable",match={class="^(org[.]gnome[.]Nautilus)$"},tag="+hyprglass_disabled"})
            end
            rules.impasto_tahoe_nautilus_disable:set_enabled(${files?"false":"true"})
            rules.impasto_tahoe_nautilus_enable:set_enabled(${files&&!frostFiles?"true":"false"})
            rules.impasto_tahoe_nautilus_preset:set_enabled(${files&&!frostFiles?"true":"false"})
            if not rules.impasto_file_dialog_enable or _G.impastoFileGlassRuleVersion~=2 then
                rules.impasto_file_dialog_enable=hl.window_rule({name="impasto-file-dialog-enable",match={class="^(xdg-desktop-portal-gtk|impasto-file-dialog)$"},tag="+hyprglass_enabled"})
                rules.impasto_file_dialog_preset=hl.window_rule({name="impasto-file-dialog-preset",match={class="^(xdg-desktop-portal-gtk|impasto-file-dialog)$"},tag="+hyprglass_preset_impasto_tahoe"})
            end
            _G.impastoFileGlassRuleVersion=2
            if not rules.impasto_file_dialog_disable then
                rules.impasto_file_dialog_disable=hl.window_rule({name="impasto-file-dialog-disable",match={class="^(xdg-desktop-portal-gtk|impasto-file-dialog)$"},tag="+hyprglass_disabled"})
            end
            rules.impasto_file_dialog_disable:set_enabled(${dialogs?"false":"true"})
            rules.impasto_file_dialog_enable:set_enabled(${dialogs?"true":"false"})
            rules.impasto_file_dialog_preset:set_enabled(${dialogs?"true":"false"})
            rules.impasto_file_dialog_opacity=hl.window_rule({name="impasto-file-dialog-opacity",match={class="^(xdg-desktop-portal-gtk|impasto-file-dialog)$"},opacity="${dialogOpacity} override ${dialogOpacity} override",enabled=${dialogs?"true":"false"}})
            -- A window can retain the old shell-wide disable tag after its
            -- rule is disabled. Reconcile Settings independently of targetKey:
            -- QML reloads and compositor reloads can keep the same toggles.
            if ${settingsWanted?"true":"false"} then
                for _,w in ipairs(hl.get_windows()) do
                    if (w.class=="org.quickshell" or w.class=="quickshell") and w.title=="Hyprland Settings" then
                        hl.dispatch(hl.dsp.window.tag({tag="-hyprglass_disabled*",window=w}))
                    end
                end
            end
            local targetKey="${windows}:${terminal}:${frostTerminal}:${settingsWanted}:${frostSettings}:${files}:${frostFiles}:${dialogs}"
            if _G.impastoMacGlassTargetKey~=targetKey then
                _G.impastoMacGlassTargetKey=targetKey
                for _,w in ipairs(hl.get_windows()) do
                    local wanted=${windows?"true":"false"}
                    if w.class=="xdg-desktop-portal-gtk" or w.class=="impasto-file-dialog" then wanted=${dialogs?"true":"false"}
                    elseif w.class=="org.gnome.Nautilus" then
                        wanted=${files?"true":"false"}
                        hl.dispatch(hl.dsp.window.tag({tag="-${frostFiles?"hyprglass_preset_impasto_tahoe*":"hyprglass_preset_impasto_blur_nautilus*"}",window=w}))
                    elseif w.class=="kitty" then
                        wanted=${terminal||frostTerminal?"true":"false"}
                        hl.dispatch(hl.dsp.window.tag({tag="-${frostTerminal?"hyprglass_preset_impasto_tahoe*":"hyprglass_preset_impasto_terminal_blur*"}",window=w}))
                    elseif (w.class=="org.quickshell" or w.class=="quickshell") and w.title=="Hyprland Settings" then
                        wanted=${settingsWanted?"true":"false"}
                        hl.dispatch(hl.dsp.window.tag({tag="-${frostSettings?"hyprglass_preset_impasto_tahoe*":"hyprglass_preset_impasto_blur_settings*"}",window=w}))
                    end
                    if wanted and (w.class=="org.gnome.Nautilus" or w.class=="xdg-desktop-portal-gtk" or w.class=="impasto-file-dialog") then
                        hl.dispatch(hl.dsp.window.tag({tag="-hyprglass_disabled*",window=w}))
                    end
                    if not wanted then
                        hl.dispatch(hl.dsp.window.tag({tag="-hyprglass_preset_impasto_tahoe*",window=w}))
                        hl.dispatch(hl.dsp.window.tag({tag="-hyprglass_enabled*",window=w}))
                    end
                end
            end
        end`
    }

    readonly property string terminalBlurKey: JSON.stringify(SettingsService.terminalFrost)
    onTerminalBlurKeyChanged: if(SettingsService.terminalGround === "blur" && !terminalBlurUpdate.running)terminalBlurUpdate.start()
    readonly property Timer terminalBlurUpdate:Timer {interval:50;onTriggered:root.applyGlass()}
    readonly property string appBlurKey:JSON.stringify({files:SettingsService.nautilusBlur,settings:SettingsService.settingsBlur,filesFrost:SettingsService.nautilusFrost,settingsFrost:SettingsService.settingsFrost})
    onAppBlurKeyChanged:if(!appBlurUpdate.running)appBlurUpdate.start()
    readonly property Timer appBlurUpdate:Timer {interval:50;onTriggered:{root.applyGlass();root.applyShadow()}}
    function terminalBlurValues():var {return root.blurValues(SettingsService.terminalFrost)}
    function blurValues(options:var):var {
        const f=options||{}
        const number=(key,fallback,low,high)=>Math.max(low,Math.min(high,Number(f[key]??fallback)))
        const hex=/^#[0-9a-fA-F]{6}$/.test(f.tintColor||"")?f.tintColor:"#ffffff"
        const v={brightness:number("brightness",100,50,150)/100,contrast:number("contrast",100,50,150)/100,
            saturation:number("saturation",100,0,200)/100,vibrancy:0,adaptive_dim:0,adaptive_boost:0,
            blur_strength:number("frost",50,0,100)/25,blur_iterations:Math.round(number("passes",2,1,4)),noise_strength:number("grain",4,0,25)/1000,
            refraction_strength:0,refraction_spread:0,refraction_flow:0,lens_distortion:0,chromatic_aberration:0,self_sample:0,xray:0,
            fresnel_strength:0,fresnel_tint:0,fresnel_reflection:0,specular_strength:0,bevel_strength:0,bevel_size:0,
            edge_thickness:0,edge_thickness_px:0,edge_height:0,
            tint_color:parseInt(hex.slice(1),16)*256+Math.round(number("tint",8,0,100)*2.55),glass_opacity:1}
        return Object.assign({},v,{dark:v,light:v})
    }

    function macGlassValues():var {
        const active=!SettingsService.gameMode&&(Theme.surfaceStyle==="tahoe"||Theme.dockStyle==="tahoe"||SettingsService.macGlassSettings||SettingsService.macGlassWindows||SettingsService.macGlassNautilus||SettingsService.macGlassFileDialogs||SettingsService.macGlassTerminal||SettingsService.terminalGround==="tahoe"||SettingsService.terminalGround==="blur"||SettingsService.nautilusBlur||SettingsService.settingsBlur)
        if(!active)return Object.assign({},root.nativeGlassBefore,{enabled:root.glassOn()})
        const tint=(0xffffff00+Math.round(SettingsService.macGlassTint*.24))
        const common={brightness:1,contrast:1,saturation:1.14,vibrancy:.12,adaptive_dim:0,adaptive_boost:0,
            blur_strength:SettingsService.macGlassBlur/12,blur_iterations:1,noise_strength:0,
            refraction_strength:SettingsService.macGlassRefraction/100*1.4,refraction_spread:SettingsService.macGlassSpread/100,refraction_flow:SettingsService.macGlassFlow/100,
            lens_distortion:SettingsService.macGlassRefractionMode==="full"?SettingsService.macGlassCentreStrength/100*SettingsService.macGlassRefraction/100:0,chromatic_aberration:0,self_sample:0,xray:0,
            fresnel_strength:SettingsService.macGlassShine/100,fresnel_tint:0,fresnel_reflection:0,
            specular_strength:SettingsService.macGlassShine/100*1.4,bevel_strength:.18,bevel_size:1,
            edge_thickness:.035,edge_thickness_px:SettingsService.macGlassEdgeWidth,edge_height:0,tint_color:tint,glass_opacity:1}
        return Object.assign({},common,{enabled:active||root.glassOn(),default_preset:"impasto_original",dark:common,light:common,
            windows:{live_resample:true,live_resample_fps:60}})
    }

    function macGlassLayerValues():var {
        const get=key=>SettingsService.macGlassBarProfile[key]??SettingsService[key]
        const p=Math.max(0,get("macGlassRefraction"))
        const bend=Math.max(1,Math.min(12,Theme.capsuleHeight*.22))*p/(p+100)
        const v=Object.assign({},root.macGlassValues())
        delete v.dark;delete v.light;delete v.windows;delete v.enabled;delete v.default_preset
        return Object.assign(v,{refraction_strength:bend/50,edge_thickness:get("macGlassEdgeWidth")/500,edge_thickness_px:0,
            refraction_spread:get("macGlassSpread")/100,refraction_flow:0,lens_distortion:0,edge_height:0,
            blur_strength:get("macGlassBlur")/12,tint_color:0xffffff00+Math.round(get("macGlassTint")*.24),
            fresnel_strength:get("macGlassShine")/100,specular_strength:get("macGlassShine")/100*1.4})
    }
    readonly property Process glassBootstrap:Process {
        command:[Quickshell.shellPath("scripts/ensure-glass-plugin.py")]
        running:true
        onExited:{root.applyGlass();root.applyLiquidLayer()}
        stderr:StdioCollector {onStreamFinished:if(text.trim())console.warn(text.trim())}
    }
    readonly property bool windowGlass: SettingsService.windowGlass

    function liquidLayerWanted(): bool {
        return (Theme.surfaceStyle === "liquid" || Theme.surfaceStyle === "tahoe" || Theme.dockStyle==="tahoe") && !SettingsService.gameMode
    }

    // Keep Hyprglass enabled whenever either windows or the liquid bar need it.
    function glassOn(): bool {
        return !SettingsService.gameMode
            && SettingsService.windowGlass
    }

    // Reapply the layer preset as liquid controls or the adaptive accent changes.
    readonly property string liquidGlassKey:
        `${Theme.surfaceStyle}:${SettingsService.gameMode}:${SettingsService.windowGlass}:${SettingsService.liquidOpacity}:${SettingsService.liquidTint}:${SettingsService.liquidShine}:${SettingsService.liquidRefraction}:${SettingsService.liquidBlur}:${String(Theme.accent)}:${SettingsService.macGlassWindows}:${SettingsService.macGlassTerminal}:${SettingsService.macGlassSettings}:${SettingsService.macGlassNautilus}:${SettingsService.macGlassFileDialogs}:${SettingsService.macGlassFileDialogOpacity}:${SettingsService.terminalGround}:${SettingsService.macGlassBlur}:${SettingsService.macGlassRefraction}:${SettingsService.macGlassTint}:${SettingsService.macGlassShine}:${SettingsService.macGlassRefractionMode}:${SettingsService.macGlassEdgeWidth}:${SettingsService.macGlassSpread}:${SettingsService.macGlassCentreStrength}:${SettingsService.macGlassFlow}:${Theme.capsuleHeight}:${JSON.stringify(SettingsService.macGlassBarProfile)}`

    onLiquidGlassKeyChanged: root.liquidGlassDebounce.restart()

    readonly property Timer liquidGlassDebounce: Timer {
        interval: 100
        onTriggered: {
            root.applyGlass()
            root.applyShadow()
            root.applyGround()
        }
    }

    // Glass depends on the shadow decoration (see shadowChunk).
    onWindowGlassChanged: {
        root.applyGlass()
        root.applyShadow()
        root.applyGround()
    }

    // ── THE BAR AND THE DOCK GROUNDS ────────────────────────────────────────
    //
    // In liquid mode the layer alpha mask drives Hyprglass directly, with native
    // blur disabled so an unsupported layer hook cannot leave a frosted fallback.
    // Other see-through styles keep their existing Hyprland blur.
    function liquidLayerChunk(): string {
        const active = root.liquidLayerWanted()
        if((Theme.surfaceStyle==="tahoe" || Theme.dockStyle==="tahoe") && !SettingsService.gameMode) {
            return `if hl.plugin.hyprglass ~= nil then
                local hg=hl.plugin.hyprglass
                hg.config({layers={enabled=true,manage_blur=true,mask_mode="contour",mask_threshold=0.12,mask_feather=0.02,live_resample=true,live_resample_fps=60}})
                hg.layer("impasto-bar",{preset="impasto_tahoe_bar",mask_mode="contour",mask_threshold=0.12,live_resample=true})
                hg.layer("impasto-dock",{preset="impasto_tahoe_bar",mask_mode="contour",mask_threshold=0.12,live_resample=true})
            end`
        }
        const accent = Theme.accent
        const byte = value => Math.max(0, Math.min(255, Math.round(value * 255)))
            .toString(16).padStart(2, "0")
        const alpha = byte((12 + SettingsService.liquidTint * 0.28) / 255)
        const tint = `0x${byte(accent.r)}${byte(accent.g)}${byte(accent.b)}${alpha}`
        const opacity = (SettingsService.liquidOpacity / 100).toFixed(2)
        const fresnel = (0.38 + SettingsService.liquidShine * 0.0035).toFixed(2)
        const specular = (0.48 + SettingsService.liquidShine * 0.004).toFixed(2)
        return `if hl.plugin.hyprglass ~= nil then
            local hg = hl.plugin.hyprglass
            hg.config({ enabled = ${root.glassOn() ? "true" : "false"}, layers = {
                enabled = ${active ? "true" : "false"},
                namespaces = "impasto-bar", manage_blur = true
            } })
            if ${active ? "true" : "false"} then
                hg.preset("impasto-liquid", {
                    inherits = "clear",
                    glass_opacity = ${opacity},
                    blur_strength = ${(SettingsService.liquidBlur / 100).toFixed(2)}, blur_iterations = 1, noise_strength = 0.0,
                    saturation = 1.0, vibrancy = 0.22,
                    refraction_strength = ${(SettingsService.liquidRefraction / 100).toFixed(2)}, refraction_spread = 0.08,
                    chromatic_aberration = 0.0,
                    fresnel_strength = ${fresnel}, fresnel_tint = 0.0,
                    specular_strength = ${specular}, specular_angle = 315.0,
                    bevel_strength = 0.26, bevel_size = 1.5, bevel_angle = 315.0,
                    edge_thickness = 0.035, edge_height = 8.0, tint_color = ${tint}
                })
                hg.layer("impasto-bar", { exclude=false, preset = "impasto-liquid",
                    mask_threshold = 0.025, mask_mode = "auto", live_resample = true })
            end
        end`
    }

    // Serialize slider updates so a rapid drag cannot leave Hyprglass on an older preset.
    property bool liquidUpdatePending: false

    function applyLiquidLayer(): void {
        if(root.glassBootstrap.running){root.liquidUpdatePending=true;return}
        if (root.liquidSetter.running) {
            root.liquidUpdatePending = true
            return
        }
        root.liquidUpdatePending = false
        root.liquidSetter.command = ["hyprctl", "eval", root.liquidLayerChunk()]
        root.liquidSetter.running = true
    }

    readonly property Process liquidStatusReader: Process {
        command: ["hyprctl", "-j", "hyprglass", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const status = JSON.parse(text)
                    const layers = status.features?.layers
                    if (root.liquidLayerWanted() && (!layers || !layers.active))
                        console.warn("Hyprglass bar layer is inactive:", layers?.reason ?? "status unavailable")
                } catch (error) {
                    console.warn("Cannot read Hyprglass layer status:", text.trim())
                }
            }
        }
    }

    readonly property Process liquidSetter: Process {
        onExited: {
            if (root.liquidUpdatePending) {
                root.liquidUpdatePending = false
                root.applyLiquidLayer()
            } else {
                root.liquidStatusReader.running = true
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "" && text.trim() !== "ok")
                    console.info("Hyprglass layer config result:", text.trim())
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "")
                    console.warn("Hyprglass layer configuration:", text.trim())
            }
        }
    }

    property bool groundUpdatePending: false

    function applyGround(): void {
        if (root.groundSetter.running) {
            root.groundUpdatePending = true
            return
        }
        root.groundUpdatePending = false
        root.groundSetter.command = ["hyprctl", "eval",
            `hl.layer_rule({ name = "impasto-bar-blur", match = { namespace = "^(impasto-bar)$" }, blur = true, ignore_alpha = 0.12, enabled = ${
                Theme.solid || Theme.surfaceStyle==="tahoe" || SettingsService.gameMode ? "false" : "true"} }) `
            + `hl.layer_rule({ name = "impasto-dock-blur", match = {
                namespace = "^(impasto-dock)$" }, blur = true, ignore_alpha = 0.12, enabled = ${
                root.dockSeeThrough && Theme.dockStyle!=="tahoe" && !SettingsService.gameMode ? "true" : "false"} })`]
        root.groundSetter.running = true
    }

    readonly property Process groundSetter: Process {
        onExited: {
            if (root.groundUpdatePending) {
                root.groundUpdatePending = false
                root.applyGround()
            } else {
                root.applyLiquidLayer()
            }
        }
    }

    readonly property bool solidGround: Theme.solid
    readonly property bool dockSeeThrough: Theme.dockGlass || SettingsService.dockOpacity < 100

    onSolidGroundChanged: root.applyGround()
    onDockSeeThroughChanged: root.applyGround()
}
