// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   M O T I O N                                                            │
// │   singleton · how the compositor moves, described once                   │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick
import Quickshell
import "../services"

// Hyprland animation presets, pushed by CompositorService. Each is one bezier
// and three durations, in deciseconds (2.6 = 260 ms):
//
//   slow    geometry
//   medium  appearing and disappearing
//   fast    colour changes
//
// `windows` and `workspaces` are Hyprland animation styles; a `popin`
// percentage is the size a window starts at. Labels deliberately differ from
// the shell's own curve names (Smooth, Snappy, Springy).
Singleton {
    id: root

    readonly property var presets: [
        {id:"feather",label:"Feather",group:"calm",note:"Almost no scaling, with a gentle finish.",curve:[.2,.8,.2,1],slow:2.8,medium:2.2,fast:1.6,windows:"popin 99%",workspaces:"fade"},
        {id:"tide",label:"Tide",group:"calm",note:"A soft sliding entrance with a restrained spring.",curve:[.18,.85,.2,1.04],slow:4,medium:3,fast:2,windows:"slide",workspaces:"slide"},
        {id:"cushion",label:"Cushion",group:"calm",note:"A cushioned expansion with a small rebound.",curve:[.17,.85,.24,1.1],slow:3.6,medium:2.6,fast:1.8,windows:"popin 96%",workspaces:"fade"},
        {id:"quick-dissolve",label:"Quick dissolve",group:"fade",fadeOnly:true,note:"A short clean dissolve without movement.",curve:[.2,.5,.3,1],slow:1.6,medium:1.6,fast:1.4,windows:"popin 100%",workspaces:"fade"},
        {id:"cinema",label:"Cinema",group:"fade",fadeOnly:true,note:"An easy, gradual crossfade.",curve:[.3,.05,.3,1],slow:3.8,medium:3.8,fast:3.2,windows:"popin 100%",workspaces:"fade"},
        {
            // Id kept for existing settings files.
            id: "macos",
            label: "Glide",
            note: "Scales into place and decelerates with a long tail. Quick, and it never bounces.",
            curve: [0.32, 0.72, 0, 1],
            slow: 2.6, medium: 1.8, fast: 1.4,
            windows: "slide", workspaces: "slide"
        },
        {
            id: "snappy",
            label: "Brisk",
            note: "Half the distance and half the time. Movement you register rather than watch.",
            curve: [0.22, 1, 0.36, 1],
            slow: 1.3, medium: 1.0, fast: 0.8,
            windows: "popin 94%", workspaces: "slide"
        },
        {
            id: "smooth",
            label: "Calm",
            note: "Long and soft, and the screen fades between workspaces rather than sliding.",
            curve: [0.25, 0.1, 0.25, 1],
            slow: 4.2, medium: 3.0, fast: 2.2,
            windows: "popin 85%", workspaces: "fade"
        },
        {
            id: "springy",
            label: "Bounce",
            note: "Overshoots a little and settles back. The look most Hyprland presets are after.",
            curve: [0.05, 0.9, 0.1, 1.15],
            slow: 3.2, medium: 2.0, fast: 1.4,
            windows: "popin 80%", workspaces: "slide"
        },
        {
            id: "off",
            label: "None",
            note: "Nothing moves. Windows and workspaces appear where they are going to be."
        },
        {
            id: "silk", label: "Silk", group: "calm",
            note: "A small, soft expansion with a gentle finish.",
            curve: [0.22, 0.75, 0.3, 1],
            slow: 3.5, medium: 2.5, fast: 1.8,
            windows: "popin 98%", workspaces: "fade"
        },
        {
            id: "drift", label: "Drift", group: "calm",
            note: "A slower expansion that eases in and out without overshooting.",
            curve: [0.3, 0.05, 0.25, 1],
            slow: 5.5, medium: 3.8, fast: 2.5,
            windows: "popin 95%", workspaces: "fade"
        },
        {
            id: "soft-spring", label: "Soft Spring", group: "calm",
            note: "A small spring with a restrained rebound.",
            curve: [0.16, 0.9, 0.25, 1.08],
            slow: 3.8, medium: 2.4, fast: 1.6,
            windows: "popin 94%", workspaces: "slide"
        },
        {
            id: "rubber", label: "Rubber", group: "calm",
            note: "A more noticeable stretch that settles softly into place.",
            curve: [0.12, 0.85, 0.24, 1.18],
            slow: 4.5, medium: 2.8, fast: 1.8,
            windows: "popin 88%", workspaces: "slide"
        },
        {
            id: "fade", label: "Fade", group: "fade", fadeOnly: true,
            note: "A clean fade in and out with no opening or closing movement.",
            curve: [0.22, 0.6, 0.35, 1],
            slow: 2.2, medium: 2.2, fast: 2.2,
            windows: "popin 100%", workspaces: "fade"
        },
        {
            id: "slow-fade", label: "Slow Fade", group: "fade", fadeOnly: true,
            note: "A longer, gentle dissolve in and out without scaling or sliding.",
            curve: [0.3, 0, 0.3, 1],
            slow: 4.8, medium: 4.8, fast: 4.8,
            windows: "popin 100%", workspaces: "fade"
        }
    ]

    function preset(id: string): var {
        return root.presets.find(entry => entry.id === id) ?? root.presets[0]
    }

    function labelOf(id: string): string {
        return root.preset(id).label
    }

    function noteOf(id: string): string {
        return root.preset(id).note
    }

    // The preset as a single Lua chunk for `hyprctl eval`, so it applies
    // atomically rather than one leaf per process.
    function chunk(id: string): string {
        const entry = root.preset(id)

        if (entry.id === "off")
            return "hl.config({ animations = { enabled = false } })"

        const options=Object.assign({},SettingsService.pristine.windowMotion,SettingsService.windowMotion)
        const curves={smooth:[.2,.8,.2,1],cinematic:[.65,0,.35,1],gentle:[.16,1,.3,1],spring:[.22,1,.36,1.08],linear:[0,0,1,1]}
        const c=(curves[options.curve]||entry.curve).slice()
        c[3]=Math.min(1,c[3])+Math.max(0,c[3]-1)*SettingsService.windowAnimationBounce/100
        const factor=100/Math.max(25,SettingsService.windowAnimationSpeed)
        const match=String(entry.windows||"").match(/popin\s+(\d+)%/)
        const windowStyle=match?"popin "+Math.round(Math.max(20,100-(100-Number(match[1]))*SettingsService.windowAnimationAmount/100))+"%":entry.windows
        const workspaceStyle=SettingsService.windowWorkspaceMotion==="preset"?entry.workspaces:SettingsService.windowWorkspaceMotion

        const lines = ["hl.config({ animations = { enabled = true } })",
                       `hl.curve("preset", { type = "bezier", points = { {${c[0]}, ${c[1]}}, {${c[2]}, ${c[3]}} } })`]

        function leaf(name, speed, style) {
            const tail = style ? `, style = "${style}"` : ""
            lines.push(`hl.animation({ leaf = "${name}", enabled = true, speed = ${(speed*factor).toFixed(2)}, bezier = "preset"${tail} })`)
        }

        function rate(value,percent){return value*100/Math.max(25,Number(percent)||100)}
        function style(choice){return choice==="popin"?"popin "+Math.round(Math.max(20,100-20*SettingsService.windowAnimationAmount/100))+"%":choice==="slide"?"slide":windowStyle}
        const openFade=options.openStyle==="fade"||(options.openStyle==="preset"&&entry.fadeOnly)
        const closeFade=options.closeStyle==="fade"||(options.closeStyle==="preset"&&entry.fadeOnly)
        const openDuration=rate(openFade?entry.medium:entry.slow,options.openSpeed)
        const closeDuration=rate(closeFade?entry.medium:Math.max(3.2,entry.medium),options.closeSpeed)

        // Parent first, so unnamed leaves inherit the preset instead of
        // Hyprland's default.
        leaf("global", entry.slow)

        leaf("windows", rate(entry.slow,options.moveSpeed))
        if(openFade)lines.push('hl.animation({ leaf = "windowsIn", enabled = false })')
        else leaf("windowsIn",openDuration,style(options.openStyle))
        if(closeFade)lines.push('hl.animation({ leaf = "windowsOut", enabled = false })')
        else leaf("windowsOut",closeDuration,style(options.closeStyle))
        leaf("workspaces",rate(entry.slow,options.workspaceSpeed),workspaceStyle)
        leaf("workspacesIn",rate(entry.slow,options.workspaceSpeed),workspaceStyle)
        leaf("workspacesOut",rate(entry.slow,options.workspaceSpeed),workspaceStyle)

        leaf("layers", entry.medium)
        leaf("layersIn", entry.medium, "fade")
        leaf("layersOut", entry.fast, "fade")

        leaf("fade", entry.medium)

        // Opacity shares the window's duration, with a smooth curve that
        // never overshoots. Transparent glass should not appear in one frame.
        lines.push('hl.curve("windowFade", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })')
        lines.push(`hl.animation({ leaf = "fadeIn", enabled = true, speed = ${(rate(openDuration,options.fadeSpeed)*factor).toFixed(2)}, bezier = "windowFade" })`)

        lines.push('hl.curve("closeFade", { type = "bezier", points = { {0.4, 0}, {0.6, 1} } })')
        lines.push(`hl.animation({ leaf = "fadeOut", enabled = true, speed = ${(rate(closeDuration,options.fadeSpeed)*factor).toFixed(2)}, bezier = "closeFade" })`)
        leaf("fadeLayersIn", entry.medium)
        leaf("fadeLayersOut", entry.fast)

        leaf("border", entry.fast)

        return lines.join(" ")
    }
}
