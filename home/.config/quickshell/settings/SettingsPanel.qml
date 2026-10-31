// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   S E T T I N G S   P A N E L                                            │
// │   sections on the left, one page at a time on the right                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls as Controls

import "../theme"
import "../services"
import "../components"

// Sidebar and page. `SettingsWindow` owns the window; this owns the sections.
//
// Settings are filed by what they change, not by how they are applied, so the
// window rounding is under Appearance rather than on a compositor page. The
// sidebar is grouped into categories and a long section is split into parts
// (`TabStrip`): two levels of navigation, no more.
//
// Where an option is a shape, the control is a live miniature built from the
// real components (`PreviewTile`), so it follows the palette and cannot go
// stale the way a screenshot would.
Item {
    id: root

    signal closed()
    signal panelRequested(string panel)

    readonly property var design:SettingsDesignService.style
    readonly property bool forma:SettingsDesignService.forma
    readonly property bool modern: SettingsDesignService.modern
    signal moveRequested()
    signal minimizeRequested()
    signal maximizeRequested()
    property var pendingNavigation: null
    property bool committingNavigation: false
    function navigateWithMotion(action): void {
        if (!root.modern || root.committingNavigation || !pageRegion.visible) { root.committingNavigation=true; action(); root.committingNavigation=false; return }
        root.pendingNavigation = action
        if (!pageExit.running) { pageEnter.stop(); pageExit.start() }
    }
    ParallelAnimation {
        id: pageExit
        NumberAnimation { target: pageRegion; property: "opacity"; to: 0; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: pageShift; property: "x"; to: -6; duration: 100; easing.type: Easing.OutCubic }
        onFinished: {
            const action=root.pendingNavigation; root.pendingNavigation=null
            root.committingNavigation=true
            if(action)action()
            root.committingNavigation=false
            pageReveal.restart()
        }
    }
    ParallelAnimation {
        id: pageEnter
        NumberAnimation { target: pageRegion; property: "opacity"; from: 0; to: 1; duration: root.modern ? 180 : 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: pageShift; property: "x"; from: root.modern ? 6 : 0; to: 0; duration: root.modern ? 180 : 100; easing.type: Easing.OutCubic }
    }
    Timer {id:pageReveal;interval:16;onTriggered:pageEnter.restart()}
    function openOverview(category:string):void {
        if(root.atlasOverview && root.atlasCategory===category)return
        root.navigateWithMotion(()=>{root.atlasCategory=category;root.atlasOverview=true})
    }
    function navigationMotionState():var{return {leaving:pageExit.running,entering:pageEnter.running,opacity:pageRegion.opacity,offset:pageShift.x,overview:root.atlasOverview}}
    readonly property bool studio: root.design.navigation === "studio"
    readonly property bool overviewDesign: root.atlas || root.studio
    readonly property int displayedPresets: pageLoader.item?.presets?.length || 0
    readonly property int presetColumns: pageLoader.item?.previewColumns || 0
    readonly property bool saving: SettingsService.file.saver.running || AccountService.busy !== "" || AccountService.namePause.running
    readonly property bool atlas: root.design.navigation === "atlas"
    property bool atlasOverview: true
    property string atlasCategory: ""
    readonly property bool rail:root.design.navigation==="rail"
    readonly property bool topNavigation:root.design.navigation==="top"
    readonly property int gap:root.design.gap
    function scrollViewport(view:var,event:var):void {
        const delta=event.pixelDelta.y!==0?event.pixelDelta.y:event.angleDelta.y/120*40
        if(!delta)return
        view.cancelFlick()
        view.contentY=Math.max(0,Math.min(Math.max(0,view.contentHeight-view.height),view.contentY-delta*SettingsService.settingsScrollSpeed/100))
        event.accepted=true
    }

    // ── THE GROUPS ──────────────────────────────────────────────────────────

    readonly property var categories: [
        {id:"you",label:Tr.t("You"),icon:"󰀄",description:Tr.t("Your profile, picture and region")},
        {id:"presets",label:Tr.t("Presets"),icon:"󰙵",description:Tr.t("Bar, launchers, modules, animations and settings designs")},
        {id:"personalization",label:Tr.t("Personalization"),icon:"󰏘",description:Tr.t("Colours, wallpaper and settings design")},
        {id:"bar",label:Tr.t("Bar & dock"),icon:"󰧨",description:Tr.t("Island, chips, workspaces and controls")},
        {id:"apps",label:Tr.t("Apps & modules"),icon:"󰍉",description:Tr.t("Launcher, notes and module appearance")},
        {id:"desktop",label:Tr.t("Windows & displays"),icon:"󰖯",description:Tr.t("Window effects, screens and desktop widgets")},
        {id:"input",label:Tr.t("Input & shortcuts"),icon:"󰌌",description:Tr.t("Keyboard, pointer and keybindings")},
        {id:"session",label:Tr.t("Lock & session"),icon:"󰌾",description:Tr.t("Lock screen, login and idle behaviour")},
        {id:"system",label:Tr.t("System"),icon:"󰍛",description:Tr.t("Profiles, updates, language and machine information")}
    ]

    // ── THE SECTIONS ────────────────────────────────────────────────────────
    //
    // One row per page. `keywords` are extra search terms beyond the label.
    readonly property var sections: [
        {id:"barpresets",category:"presets",icon:"󰧨",label:Tr.t("Bar presets"),blurb:Tr.t("Floating bars, notches and individual chips."),tabs:[],keywords:"presets designs bar",presetKind:"bar",page:presetPage},
        {id:"barcolour",category:"presets",icon:"󰏘",label:Tr.t("Bar Colour"),blurb:Tr.t("Black/grey, Glass and both Liquid Glass materials, shared by modules."),tabs:[],keywords:"bar colour color black grey classic liquid glass material modules",presetKind:"barcolour",page:presetPage},
        {id:"macglasspresets",category:"presets",icon:"󰘖",label:Tr.t("MacShell glass"),blurb:Tr.t("Save independent bar, module, window, Settings, terminal and password-pill glass values."),tabs:[],keywords:"macshell liquid glass refraction save preset blur tint transparency terminal",presetKind:"macglass",page:presetPage},
        {id:"libraries",category:"apps",icon:"󰈙",label:Tr.t("Libraries"),blurb:Tr.t("Preset browsing and document rows and animations."),tabs:[],keywords:"preset library carousel menu documents files rows animation",page:librariesPage},
        {id:"launcherpresets",category:"presets",icon:"󰍉",label:Tr.t("Launcher presets"),blurb:Tr.t("Compact, minimal and expanded app launchers."),tabs:[],keywords:"presets designs launcher",presetKind:"launcher",page:presetPage},
        {id:"modulepresets",category:"presets",icon:"󰆧",label:Tr.t("Module presets"),blurb:Tr.t("Save and apply designs for every module."),tabs:[],keywords:"presets designs modules",presetKind:"modules",page:presetPage},
        {id:"lockdesignpresets",category:"presets",icon:"󰌾",label:Tr.t("Lock screen designs"),blurb:Tr.t("Saved clock, profile and password-pill layouts."),tabs:[],keywords:"lockscreen reference macos design preset",presetKind:"lockscreen",page:presetPage},
        {id:"lockmotionpresets",category:"presets",icon:"󰌾",label:Tr.t("Lock animations"),blurb:Tr.t("Saved lock, unlock and desktop entry animations."),tabs:[],keywords:"presets designs lockmotion",presetKind:"lockmotion",page:presetPage},
        {id:"shellmotionpresets",category:"presets",icon:"󰐎",label:Tr.t("Shell animations"),blurb:Tr.t("Shared shell motion, per-module opening and closing, and hover delays."),tabs:[{id:"presets",label:Tr.t("Presets")},{id:"customize",label:Tr.t("Customize")},{id:"opening",label:Tr.t("Opening & closing")},{id:"hover",label:Tr.t("Hover delays")}],keywords:"presets designs shellmotion module bar island opening closing animations speed easing fades bounce hover delay",presetKind:"shellmotion",page:shellAnimationsPage},
        {id:"windowmotionpresets",category:"presets",icon:"󰖯",label:Tr.t("Window animations"),blurb:Tr.t("Hyprland window animation designs."),tabs:[],keywords:"presets designs windowmotion",presetKind:"windowmotion",page:presetPage},
        {id:"profile",category:"you",icon:"󰀄",label:Tr.t("Profile"),blurb:Tr.t("Your photo, display name and regional preferences."),tabs:[{id:"account",label:Tr.t("Account")},{id:"region",label:Tr.t("Region")}],keywords:"profile account user username avatar picture photo display name language region timezone time zone",page:profilePage},
        {id:"setuppresets",category:"presets",icon:"󰙵",label:Tr.t("Full setups"),blurb:Tr.t("Save and restore the bar, launcher, modules, lock screen and desktop together."),tabs:[],keywords:"full whole complete setup preset profile snapshot save update delete bar launcher modules",presetKind:"setup",page:presetPage},
        {id:"settingsdesign",category:"presets",icon:"󰙵",label:Tr.t("Settings designs"),blurb:Tr.t("Choose navigation, density and saved settings layouts."),tabs:[],keywords:"settings design layout navigation presets compact rail ribbon explorer saved theme",presetKind:"designs",page:presetPage},
        {id:"bar",category:"bar",icon:"󰧨",label:Tr.t("Bar & Island"),
         blurb:Tr.t("Bar style, layout, Island, indicators, chips, presets and notifications."),
         tabs:[{id:"style",label:Tr.t("Bar style")},
               {id:"workspaces",label:Tr.t("Workspace style & shortcuts")},
               {id:"island",label:Tr.t("Island behaviour")},{id:"indicators",label:Tr.t("Clock & pill")},
               {id:"islandworkspaces",label:Tr.t("Workspace indicators")},{id:"network",label:Tr.t("Network")},
               {id:"bluetooth",label:Tr.t("Bluetooth")},{id:"volume",label:Tr.t("Volume")},
               {id:"battery",label:Tr.t("Battery")},{id:"chips",label:Tr.t("Individual chips")},
               {id:"notifications",label:Tr.t("Notifications")}],
         keywords:"bar island notch floating style layout ground classic glass liquid opacity refraction blur shadow rounding clock time date seconds width height padding battery network wifi signal bluetooth speaker volume chip icon position size offset workspace glow notifications presets save restore hover click modules media animation expansion opening closing speed easing fade",page:barPage},

        {id:"barautohide",category:"bar",icon:"󰖯",label:Tr.t("Auto-hide animations"),blurb:Tr.t("Choose how the bar disappears and returns, with separate timing and movement controls."),tabs:[{id:"style",label:Tr.t("Animation")},{id:"timing",label:Tr.t("Timing & movement")}],keywords:"smart auto hide intellihide window overlap bar island pill animation reveal fade slide spring timing delay",page:autoHidePage},
        { id: "controls", category: "bar", icon: "󰕰", label: Tr.t("Control Centre"),
          blurb: Tr.t("What the island opens onto when you click it."),
          tabs: [{id:"layout",label:Tr.t("Layout")} , {id:"actions",label:Tr.t("Quick actions")} ],
          keywords: "controls control centre center panel doors buttons row games notes tasks stats blocks grid toggles tiles arrange edit tray wifi bluetooth airplane microphone focus",
          page: controlsPage },

        { id: "launcher", category: "apps", icon: "󰍉", label: Tr.t("Launcher"),
          blurb: Tr.t("Design, presets, search and the clipboard history."),
          tabs: [{ id:"layout",label:Tr.t("Layout") },{ id:"appearance",label:Tr.t("Appearance") },{ id:"motion",label:Tr.t("Motion") },{ id: "results", label: Tr.t("Results") },
                 { id: "sigils", label: Tr.t("Sigils") },
                 { id: "clipboard", label: Tr.t("Clipboard") }],
          keywords: "launcher search apps results calculate run window timer note task prefix sigil order recent frequency clipboard history copy paste images wipe lock",
          page: launcherPage },

        { id: "dock", category: "bar", icon: "󱂩", label: Tr.t("Dock"),
          blurb: Tr.t("The dock and the applications kept on it."),
          tabs: [{id:"layout",label:Tr.t("Layout")} , {id:"appearance",label:Tr.t("Appearance")} , {id:"behavior",label:Tr.t("Behaviour")} , {id:"apps",label:Tr.t("Pinned apps")} ],
          keywords: "dock apps applications launcher pinned kept favourite favorite running edge bottom left right align icon size magnify ground glass classic liquid background opacity shadow autohide taskbar menu windows close every screen monitors",
          page: dockPage },

        { id: "widgets", category: "desktop", icon: "󰕮", label: Tr.t("Desktop"),
          blurb: Tr.t("What sits on the wallpaper, under the windows."),
          tabs: [{id:"layout",label:Tr.t("Layout")} , {id:"appearance",label:Tr.t("Appearance")} , {id:"behavior",label:Tr.t("Behaviour")} ],
          keywords: "widgets desktop wallpaper widget place drag size shape arrange edit tray face theme analogue modern sticker ground glass classic liquid background opacity shadow edges deck notes spectrum empty workspace",
          page: widgetsPage },

        { id: "modules", category: "apps", icon: "󰆧", label: Tr.t("Modules"),
          blurb: Tr.t("What the modules know, on the bar, the desktop and the panels."),
          tabs: [{ id:"colours",label:Tr.t("Colours") },{id:"weather",label:Tr.t("Weather")} , {id:"github",label:Tr.t("GitHub")} , {id:"markets",label:Tr.t("Markets")} , {id:"notes",label:Tr.t("Notes")} , {id:"lyrics",label:Tr.t("Lyrics")} , {id:"rounding",label:Tr.t("Rounding")}  ],
          keywords: "modules weather location place city github contributions username markets crypto bitcoin price currency exchange rate lyrics lrclib song music notes note handwriting",
          page: modulesPage },

        {id:"terminal",category:"apps",icon:"󰆍",label:Tr.t("Terminal"),blurb:Tr.t("Terminal background, startup greeting and scenes."),tabs:[{id:"terminal",label:Tr.t("Appearance & greeting")}],keywords:"terminal kitty ground background greeting fastfetch startup",page:appearancePage},
        {id:"settingsappearance",category:"personalization",icon:"󰏘",label:Tr.t("Appearance"),blurb:Tr.t("A workspace that feels like you. Fine-tune the little things."),tabs:[{id:"colours",label:Tr.t("Colours")},{id:"layout",label:Tr.t("Layout")},{id:"type",label:Tr.t("Typography")},{id:"details",label:Tr.t("Details")},{id:"sidebarcolours",label:Tr.t("Sidebar colours")}],keywords:"settings appearance design light dark black accent colours colors customize font sidebar spacing cards controls accessibility",page:settingsAppearancePage},
        { id: "appearance", category: "personalization", icon: "󰏘", label: Tr.t("Wallpaper & fonts"),
          blurb: Tr.t("Wallpaper, terminal, fonts and the shell's motion."),
          tabs: [{ id: "theme", label: Tr.t("Themes") },
                 { id: "editor", label: Tr.t("Theme editor") },
                 { id: "wallpaper", label: Tr.t("Wallpaper") },
                 { id: "type", label: Tr.t("Fonts") }],
          keywords: "appearance theme colour color palette wallpaper transition fade wipe wave circle random terminal kitty ground glass greeting fastfetch fa scene lava lamp critters koi invaders font family sans mono nerd icons typeface animation speed pace curve easing motion game mode performance",
          page: appearancePage },

        { id: "windows", category: "desktop", icon: "󰖯", label: Tr.t("Windows"),
          blurb: Tr.t("How Hyprland lays out, draws and animates windows."),
          tabs: [{id:"layout",label:Tr.t("Layout & shape")} , {id:"effects",label:Tr.t("Glass, opacity & shadows")}  ],
          keywords: "windows layout dwindle master scrolling rounding border gaps inner outer opacity inactive blur refraction glass hyprglass shadow animation preset hyprland",
          page: windowsPage },

        { id: "monitors", category: "desktop", icon: "󰍹", label: Tr.t("Displays"),
          blurb: Tr.t("Screen layout, modes and the laptop lid."),
          tabs: [{ id: "arrangement", label: Tr.t("Arrangement") },
                 { id: "screen", label: Tr.t("Resolution & scaling") },
                 { id: "lid", label: Tr.t("Laptop lid") }],
          keywords: "displays monitor screen resolution refresh scale rotate transform vrr mirror extend primary lid clamshell laptop close",
          page: monitorsPage },

        { id: "input", category: "input", icon: "󰍽", label: Tr.t("Input"),
          blurb: Tr.t("The keyboard, the pointer and the cursor."),
          tabs: [{ id: "keyboard", label: Tr.t("Keyboard") },
                 { id: "pointer", label: Tr.t("Pointer") }],
          keywords: "input keyboard layout repeat mouse sensitivity pointer cursor size colour color shake find",
          page: inputPage },

        { id: "keys", category: "input", icon: "󰌌", label: Tr.t("Keys"),
          blurb: Tr.t("Every keybinding, the shell's and Hyprland's."),
          tabs: [{ id: "shell", label: Tr.t("Shell shortcuts") },
                 { id: "compositor", label: Tr.t("Window shortcuts") }],
          keywords: "keys shortcut shortcuts binding hotkey super rebind zen hide widgets",
          page: keysPage },

        { id: "session", category: "session", icon: "󰌾", label: Tr.t("Session"),
          blurb: Tr.t("Your account, the lock screen and idle behaviour."),
          tabs: [{ id: "lock", label: Tr.t("Lock screen") },
                 { id: "animations", label: Tr.t("Lock animations") },
                 { id: "idle", label: Tr.t("Idle & power") }],
          keywords: "session lock blur password suspend security idle timeout sleep screen off dpms away never lock after avatar picture name account clock stacked inline flip music song lyrics cover now playing customization designer preview interactive drag profile pill opacity shadow boot login",
          page: sessionPage },

        { id: "system", category: "system", icon: "󰍛", label: Tr.t("System"),
          blurb: Tr.t("Profiles, updates, language and this machine."),
          tabs: [{ id: "profiles", label: Tr.t("Profiles") },
                 { id: "updates", label: Tr.t("Updates") },
                 { id: "machine", label: Tr.t("About & language") }],
          keywords: "system about version update updates upgrade changelog commits cpu memory uptime reset defaults language spanish english profile profiles switch rename duplicate delete import export backup file json changed files edited deleted restore wallpapers .new config dotfiles keep mine",
          page: systemPage }
    ]

    // ── THE GUIDE ───────────────────────────────────────────────────────────
    //
    // Where the help button takes each page, or one part of it, on the
    // documentation site. Keyed "section" or "section/part".
    readonly property string guideRoot: "https://andreumassanet.github.io/impasto-docs/"
    readonly property var guides: ({
        "bar": "shell/bar/",
        "bar/layout": "shell/bar/#arranging",
        "bar/workspaces": "shell/bar/#size-and-workspaces",
        "island": "shell/island/#settings",
        "island/indicators": "shell/island/#settings",
        "island/notifications": "shell/island/#notifications",
        "widgets": "shell/desktop/#arranging",
        "modules": "shell/desktop/",
        "controls": "shell/control-centre/#arranging",
        "dock": "shell/dock/#settings",
        "launcher": "shell/launcher/#settings",
        "launcher/sigils": "shell/launcher/#modes",
        "launcher/clipboard": "shell/launcher/#the-clipboard",
        "appearance": "shell/settings/#the-pages",
        "appearance/wallpaper": "theming/palettes/",
        "windows": "shell/settings/#the-pages",
        "monitors": "shell/displays/",
        "monitors/arrangement": "shell/displays/#arrangement",
        "monitors/screen": "shell/displays/#the-screen",
        "monitors/lid": "shell/displays/#the-lid",
        "input": "shell/settings/#the-pages",
        "keys": "shell/keys-and-packages/#changing-a-key",
        "session": "shell/lock-and-login/",
        "session/lock": "shell/lock-and-login/#the-lock-screen",
        "session/idle": "shell/lock-and-login/#when-you-leave-it-alone",
        "system": "shell/settings/#profiles",
        "system/machine": "shell/settings/#language"
    })

    readonly property string guide: root.guideRoot
        + (root.guides[`${root.section}/${root.tab}`] ?? root.guides[root.section] ?? "")

    // ── NAVIGATION ──────────────────────────────────────────────────────────
    //
    // A history rather than a single id, so a page that links to another can
    // be left with the back button.
    property var trail: [{ section: "bar", tab: "style" }]
    property int cursor: 0

    readonly property string section: root.trail[root.cursor].section
    readonly property string tab: root.trail[root.cursor].tab

    readonly property var navigationOrder:{
        const entries=[]
        for(const category of root.categories)for(const section of root.sections)if(section.category===category.id)entries.push(section)
        return entries
    }
    readonly property var current:
        root.sections.find(entry => entry.id === root.section) ?? root.sections[0]

    function firstTab(id: string): string {
        const entry = root.sections.find(other => other.id === id)
        return entry && entry.tabs.length > 0 ? entry.tabs[0].id : ""
    }

    // The part each section was last left on.
    property var visited: ({})

    function go(id: string, wanted: string): void {
        if(root.modern && !root.committingNavigation && (root.atlasOverview || id!==root.section || (wanted && wanted!==root.tab))) {
            root.navigateWithMotion(()=>root.go(id,wanted)); return
        }
        if(id === "bar" && wanted === "animations") {id="shellmotionpresets";wanted="opening"}
        if(id === "bar" && wanted === "layout")wanted="style"
        if(id === "bar" && wanted === "presets") {id="barpresets";wanted=""}
        if(id === "launcher" && wanted === "presets") {id="launcherpresets";wanted=""}
        if(id === "appearance" && wanted === "motion") {id="shellmotionpresets";wanted=""}
        if(id === "windows" && wanted === "motion") {id="windowmotionpresets";wanted=""}
        if(id === "island") {
            id="bar"
            wanted=wanted === "workspaces" ? "islandworkspaces" : wanted || "island"
        }
        root.atlasOverview = false
        root.atlasCategory = root.sections.find(e => e.id === id)?.category || ""
        const entry = root.sections.find(e => e.id === id)
        const requested = wanted || root.visited[id] || root.firstTab(id)
        const part = !entry || !entry.tabs.length || entry.tabs.some(t => t.id === requested)
            ? requested : root.firstTab(id)
        if (id === root.section && part === root.tab)
            return
        const path = root.trail.slice(0, root.cursor + 1)
        path.push({ section: id, tab: part })
        root.trail = path
        root.cursor = path.length - 1
        page.contentY = 0
    }

    function show(part: string): void {
        if(root.modern && !root.committingNavigation && part!==root.tab) {
            root.navigateWithMotion(()=>root.show(part)); return
        }
        if (part === root.tab)
            return
        const kept = Object.assign({}, root.visited)
        kept[root.section] = part
        root.visited = kept
        const path = root.trail.slice()
        path[root.cursor] = { section: root.section, tab: part }
        root.trail = path
        page.contentY = 0
        Qt.callLater(root.scrollToPart)
    }

    function back(): void {
        if(root.modern && !root.committingNavigation && root.cursor>0){root.navigateWithMotion(root.back);return}
        if (root.cursor > 0) {
            root.cursor--
            page.contentY = 0
        }
    }

    function forward(): void {
        if(root.modern && !root.committingNavigation && root.cursor<root.trail.length-1){root.navigateWithMotion(root.forward);return}
        if (root.cursor < root.trail.length - 1) {
            root.cursor++
            page.contentY = 0
        }
    }

    property string filter: ""

    function matches(entry: var): bool {
        const term = root.filter.trim().toLowerCase()
        if (term === "")
            return true
        // Labels are translated; keywords are English, so both languages match.
        const parts = entry.tabs.map(part => part.label).join(" ").toLowerCase()
        return entry.label.toLowerCase().includes(term)
            || entry.keywords.includes(term)
            || entry.blurb.toLowerCase().includes(term)
            || parts.includes(term)
    }

    readonly property var shown: root.sections.filter(entry => root.matches(entry))

    // Flattened: a heading per non-empty group followed by its sections, so a
    // single ListView and scroll position covers the whole sidebar.
    readonly property var sidebar: {
        if(root.rail)return root.shown.map(e=>({heading:false,label:e.label,icon:e.icon,id:e.id}))
        const rows = []
        for (const group of root.categories) {
            const members = root.shown.filter(entry => entry.category === group.id)
            if (members.length === 0)
                continue
            rows.push({ heading: true, label: group.label, category:group.id, id: `head:${group.id}` })
            for (const entry of members)
                rows.push({ heading: false, label: entry.label,
                            icon: entry.icon, category:entry.category, id: entry.id })
        }
        return rows
    }

    Rectangle {
        visible:root.modern
        anchors.fill:parent
        color:root.design.background
        radius:18
    }
    Rectangle {
        id:referenceTitlebar
        visible:root.modern
        anchors.left:parent.left;anchors.right:parent.right;anchors.top:parent.top
        height:48;color:root.design.titlebarBackground || root.design.sidebarBackground
        MouseArea {anchors.fill:parent;onPressed:root.moveRequested();onDoubleClicked:root.maximizeRequested()}
        Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:root.design.borderColor}
        RowLayout {
            anchors.fill:parent;anchors.leftMargin:16;anchors.rightMargin:16;spacing:12
            Row {spacing:8
                Repeater {model:[{c:"#fc5855",label:"×",name:"Close"},{c:"#f3ba25",label:"−",name:"Minimize"},{c:"#4cc157",label:"⤢",name:"Maximize"}]
                    Rectangle {
                        required property var modelData;required property int index
                        width:12;height:12;radius:6;color:modelData.c
                        Accessible.role:Accessible.Button;Accessible.name:modelData.name
                        Text {anchors.centerIn:parent;text:parent.modelData.label;font.pixelSize:10;color:"#9e1e1a16";opacity:lightHover.hovered?1:0}
                        HoverHandler {id:lightHover;cursorShape:Qt.PointingHandCursor}
                        TapHandler {onTapped:{if(index===0)root.closed();else if(index===1)root.minimizeRequested();else root.maximizeRequested()}}
                    }
                }
            }
            Item {width:6}
            Row {spacing:4
                IconButton {icon:"󰅁";iconSize:16;enabled:root.cursor>0;opacity:enabled?1:.3;onClicked:root.back()}
                IconButton {icon:"󰅂";iconSize:16;enabled:root.cursor<root.trail.length-1;opacity:enabled?1:.3;onClicked:root.forward()}
            }
            Text {text:root.atlasOverview?Tr.t("Overview"):root.current.label;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window)}
            Item {Layout.fillWidth:true}
            Text {visible:root.saving;text:Tr.t("Saving…");font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11;color:Theme.mutedIn(QsWindow.window)}
            ArchMark {size:20}
        }
    }
    GridLayout {
        anchors.fill:parent;anchors.margins:root.studio ? 0 : 14;anchors.topMargin:root.modern?48:root.studio?0:14
        columns:root.topNavigation?1:2
        columnSpacing:root.studio ? 0 : root.gap;rowSpacing:root.gap

        // ── SIDEBAR ─────────────────────────────────────────────────────────

        Rectangle {
            Layout.preferredWidth:root.topNavigation?-1:root.design.sidebarWidth
            Layout.maximumWidth:root.topNavigation?100000:root.design.sidebarWidth
            Layout.fillWidth:root.topNavigation
            Layout.fillHeight:!root.topNavigation
            Layout.preferredHeight:root.topNavigation?(topNavHost.item?.implicitHeight || 0)+24:-1
            radius:root.studio ? 0 : Math.max(8,root.design.cardRadius+6)
            color:root.design.sidebarBackground||Theme.colourIn(QsWindow.window,"fieldBackground",Theme.islandSurface)
            border.color: Theme.islandBorder
            border.width: root.studio ? 0 : 1

            Rectangle { visible:root.studio; anchors.right:parent.right; width:1; height:parent.height; color:root.design.borderColor || Theme.colourIn(QsWindow.window,"borderColor",Theme.border) }
            Loader {
                id:referenceNavHost
                anchors.fill:parent;active:root.modern
                sourceComponent: ReferenceNavigation {
                    anchors.fill:parent;anchors.margins:12
                    categories:root.categories;sections:root.shown
                    currentSection:root.section;currentCategory:root.atlasOverview&&root.atlasCategory?root.atlasCategory:root.current.category
                    overview:root.atlasOverview;filter:root.filter
                    onPicked:section=>root.go(section,"")
                    onOverviewPicked:root.openOverview("")
                    onCategoryPicked:category=>root.openOverview(category)
                    onFilterEdited:text=>{root.filter=text;if(text){root.atlasOverview=true;root.atlasCategory=""}}
                }
            }
            Loader {
                id:studioNavHost
                anchors.fill:parent
                active:root.studio && !root.modern
                sourceComponent: StudioNavigation {
                id:studioNav
                visible:root.studio
                anchors.fill:parent; anchors.margins:root.forma?root.design.sidebarPadding:14
                categories:root.categories; sections:root.shown
                currentSection:root.section; currentCategory:root.atlasOverview && root.atlasCategory ? root.atlasCategory : root.current.category
                overview:root.atlasOverview; filter:root.filter
                onPicked:section=>root.go(section, "")
                onOverviewPicked:root.openOverview("")
                onCategoryPicked:category=>root.openOverview(category)
                onFilterEdited:text=>{root.filter=text;if(text){root.atlasOverview=true;root.atlasCategory=""}}
            }
            }
            Loader {
                id:atlasNavHost
                anchors.fill:parent
                active:root.atlas
                sourceComponent: SettingsCategoryNavigation {
                anchors.fill: parent
                anchors.margins: 12
                visible: root.atlas
                categories: root.categories
                sections:root.sections
                currentSection:root.section
                currentTab:root.tab
                onSectionPicked:(section,tab)=>root.go(section,tab)
                selected: root.atlasCategory
                onCategoryPicked:category=>root.openOverview(category)
            }
            }
            Loader {
                id:topNavHost
                anchors.fill:parent
                active:root.topNavigation
                sourceComponent: ColumnLayout{
                id:topNav
                visible:root.topNavigation
                anchors.fill:parent;anchors.margins:12;spacing:8
                RowLayout{Layout.fillWidth:true
                    ArchMark{size:28}
                    Text{text:"Hyprland";font.family:Theme.fontIn(QsWindow.window);font.pixelSize:20;font.weight:Font.DemiBold;color:Theme.textIn(QsWindow.window)}
                    Item{Layout.fillWidth:true}
                    SegmentedControl{options:root.categories.map(p=>({id:p.id,label:p.label}));current:root.current.category;onSelected:id=>{const section=root.shown.find(p=>p.category===id);if(section)root.go(section.id,"")}}
                }
                Flow{Layout.fillWidth:true;spacing:6
                    Repeater{model:root.shown.filter(p=>root.filter!==""||p.category===root.current.category)
                        PillButton{required property var modelData;text:modelData.label;active:root.section===modelData.id;onClicked:root.go(modelData.id,"")}
                    }
                }
            }
            }
            Loader {
                id:legacyNavHost
                anchors.fill:parent
                active:!root.topNavigation && !root.atlas && !root.studio
                sourceComponent: ColumnLayout {
                function focusSearch():void {search.forceActiveFocus();search.selectAll()}
                visible:!root.topNavigation && !root.atlas && !root.studio
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                // ── SIGNATURE ───────────────────────────────────────────────
                //
                // The name in the script face, beside the palette board painted
                // in the active palette.
                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    implicitHeight: 38

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        ArchMark{anchors.verticalCenter:parent.verticalCenter;size:root.rail?28:34}

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible:!root.rail
                            text:"Hyprland"
                            font.family:Theme.fontIn(QsWindow.window)
                            font.weight:Font.DemiBold
                            font.pixelSize:22
                            color: Theme.textIn(QsWindow.window)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    visible:!root.rail
                    radius: Theme.radiusSmall
                    color: Theme.island
                    border.color: search.activeFocus ? Theme.accentIn(QsWindow.window) : Theme.islandBorder
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: Theme.mutedIn(QsWindow.window)
                        }

                        TextInput {
                            id: search

                            Layout.fillWidth: true
                            font.family: Theme.fontIn(QsWindow.window)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textIn(QsWindow.window)
                            selectByMouse: true
                            selectionColor: Theme.accentIn(QsWindow.window)
                            selectedTextColor: Theme.accentTextIn(QsWindow.window)
                            clip: true
                            focus: true

                            onTextEdited: root.filter = text

                            // Escape clears the field first, and closes the
                            // window only once it is empty.
                            Keys.onEscapePressed: event => {
                                if (search.text === "") {
                                    event.accepted = false
                                    return
                                }
                                search.text = ""
                                root.filter = ""
                            }

                            // Enter opens the first match.
                            Keys.onReturnPressed: {
                                if (root.shown.length > 0)
                                    root.go(root.shown[0].id, "")
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: Tr.t("Search settings")
                                font: search.font
                                color: Theme.mutedIn(QsWindow.window)
                            }
                        }
                    }
                }

                ListView {
                    id:sidebarScroll
                    WheelHandler {target:null;acceptedDevices:PointerDevice.Mouse|PointerDevice.TouchPad;onWheel:event=>root.scrollViewport(sidebarScroll,event)}
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: root.sidebar
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: entry

                        required property var modelData

                        readonly property bool active:
                            !entry.modelData.heading
                            && entry.modelData.id === root.section

                        width: ListView.view.width
                        height:entry.modelData.heading?24:root.design.navRowHeight

                        // Group heading; not clickable.
                        Text {
                            visible: entry.modelData.heading
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            text: entry.modelData.label
                            font.family: Theme.fontIn(QsWindow.window)
                            font.pixelSize: Theme.fontSizeLabel
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                            color: Theme.mutedIn(QsWindow.window)
                            opacity: 0.7
                        }

                        Rectangle {
                            visible: !entry.modelData.heading
                            anchors.fill: parent
                            radius: Theme.radiusSmall
                            color: entry.active ? Theme.colourIn(QsWindow.window,"hoverColor",Theme.islandSurfaceHover)
                                : (entryMouse.containsMouse ? Theme.island : Qt.alpha(Theme.island, 0))
                            border.color: entry.active ? Theme.accentIn(QsWindow.window) : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin:root.rail?0:11
                                anchors.rightMargin:root.rail?0:11
                                spacing:root.rail?0:11

                                Text {
                                    Layout.fillWidth:root.rail
                                    horizontalAlignment:Text.AlignHCenter
                                    text: entry.modelData.icon ?? ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: Theme.sidebarColour(entry.modelData.category,entry.active ? Theme.accentIn(QsWindow.window) : Theme.mutedIn(QsWindow.window))
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible:!root.rail
                                    text: entry.modelData.label
                                    elide: Text.ElideRight
                                    font.family: Theme.fontIn(QsWindow.window)
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: entry.active ? Font.DemiBold : Font.Normal
                                    color: Theme.sidebarTextColour(entry.modelData.category,entry.active ? Theme.accentIn(QsWindow.window) : Theme.textIn(QsWindow.window))
                                }
                            }

                            Controls.ToolTip.visible:root.rail&&entryMouse.containsMouse
                            Controls.ToolTip.text:entry.modelData.label
                            Controls.ToolTip.delay:350
                            MouseArea {
                                id: entryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.go(entry.modelData.id, "")
                            }
                        }
                    }
                }
            }
            }
        }

        // ── PAGE ────────────────────────────────────────────────────────────

        ColumnLayout {
            id:pageRegion
            transform:Translate {id:pageShift}
            Layout.margins: root.forma ? root.design.contentMargin : root.studio ? 30 : 0
            Layout.topMargin:root.modern?32:root.forma?root.design.contentMargin:root.studio?30:0
            Layout.bottomMargin:root.modern?32:root.forma?root.design.contentMargin:root.studio?30:0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap

            RowLayout {
                visible:root.studio && !root.modern && (!root.forma || root.design.showBreadcrumbs)
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: Tr.t("Settings"); color:Theme.mutedIn(QsWindow.window); font.family:Theme.fontIn(QsWindow.window); font.pixelSize:11
                    HoverHandler { cursorShape:Qt.PointingHandCursor }
                    TapHandler { onTapped:root.openOverview("") }
                }
                Text { text:"›";color:"#64708d";font.pixelSize:12 }
                Text { text:root.atlasOverview?Tr.t("Overview"):root.current.label; color:Theme.textIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:11 }
                Item { Layout.fillWidth:true }
                Rectangle { visible:!root.forma||root.design.showSavedStatus;width:7;height:7;radius:4;color:root.saving?"#e4b65e":"#50c993" }
                Text { visible:!root.forma||root.design.showSavedStatus;text:root.saving?Tr.t("Saving…"):Tr.t("All changes saved");font.family:Theme.fontMono;font.pixelSize:10;color:Theme.mutedIn(QsWindow.window) }
                IconButton { icon:"󰅖";iconSize:13;onClicked:root.closed() }
            }
            RowLayout {
                visible: !root.studio
                Layout.fillWidth: true
                spacing: 6

                IconButton {
                    icon: "󰅁"
                    iconSize: 13
                    opacity: root.cursor > 0 ? 1 : 0.3
                    onClicked: root.back()
                }

                IconButton {
                    icon: "󰅂"
                    iconSize: 13
                    opacity: root.cursor < root.trail.length - 1 ? 1 : 0.3
                    onClicked: root.forward()
                }

                PillButton {
                    visible: root.atlas
                    text: Tr.t("All settings")
                    active: root.atlasOverview && root.atlasCategory === ""
                    onClicked: { root.atlasCategory="";root.atlasOverview=true }
                }
                Item { Layout.fillWidth: true }

                Rectangle{visible:root.rail||root.topNavigation||root.atlas;Layout.preferredWidth:220;Layout.preferredHeight:30;radius:Theme.radiusSmall;color:Theme.colourIn(QsWindow.window,"fieldBackground",Theme.islandSurface);border.width:1;border.color:Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                    TextInput{id:navSearch;anchors.fill:parent;anchors.leftMargin:10;anchors.rightMargin:10;verticalAlignment:TextInput.AlignVCenter;text:root.filter;selectByMouse:true;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:Theme.fontSizeSmall;color:Theme.textIn(QsWindow.window);onTextEdited:root.filter=text
                        Text{anchors.verticalCenter:parent.verticalCenter;visible:parent.text==="";text:Tr.t("Search settings");font:parent.font;color:Theme.mutedIn(QsWindow.window)}
                        Keys.onReturnPressed:if(root.shown.length)root.go(root.shown[0].id,"")
                    }
                }
                PillButton{text:Tr.t("Design");active:root.section==="settingsdesign";onClicked:root.go("settingsdesign","")}
                // This page, or this part of it, on the documentation site.
                IconButton {
                    icon: "󰋗"
                    iconSize: 13
                    onClicked: Qt.openUrlExternally(root.guide)
                }

                IconButton {
                    icon: "󰅖"
                    iconSize: 13
                    onClicked: root.closed()
                }
            }

            SettingsOverview {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.overviewDesign && root.atlasOverview
                categories: root.categories
                sections: root.shown
                category: root.atlasCategory
                searching: root.filter !== ""
                onPicked: (section, tab) => root.go(section, tab)
                onCategoryPicked:category=>root.openOverview(category)
            }
            // One scroll area for the whole page, hero and strip included;
            // sections never scroll on their own.
            Flickable {
                id: page
                WheelHandler {target:null;acceptedDevices:PointerDevice.Mouse|PointerDevice.TouchPad;onWheel:event=>root.scrollViewport(page,event)}
                visible: !root.overviewDesign || !root.atlasOverview

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: body.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: body

                    width: root.modern && root.current.category!=="presets" ? Math.min(page.width,root.design.contentWidth || 592) : page.width
                    x: (page.width-width)/2
                    spacing: root.gap

                    RowLayout {
                        visible: root.atlas
                        spacing: 8
                        Text {
                            text: root.categories.find(c => c.id === root.current.category)?.label || ""
                            color: categoryHover.hovered ? Theme.accentIn(QsWindow.window) : Theme.mutedIn(QsWindow.window)
                            font.family: Theme.fontIn(QsWindow.window)
                            font.pixelSize: Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
                            HoverHandler { id:categoryHover; cursorShape:Qt.PointingHandCursor }
                            TapHandler { onTapped:{root.atlasCategory=root.current.category;root.atlasOverview=true} }
                        }
                        Text { text:"/";color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window) }
                        Text {
                            text:root.current.label;color:Theme.textIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window)
                            font.pixelSize:Theme.textSizeIn(QsWindow.window, Theme.fontSizeSmall)
                            HoverHandler { cursorShape:Qt.PointingHandCursor }
                            TapHandler { onTapped:root.show(root.firstTab(root.section)) }
                        }
                    }
                    RowLayout {
                        visible:root.studio
                        Layout.fillWidth:true
                        spacing:16
                        Rectangle { visible:!root.forma||root.design.headerIcon;width:root.modern?48:46;height:width;radius:14;color:root.modern?Theme.accentIn(QsWindow.window):Qt.alpha(Theme.accentIn(QsWindow.window),.13)
                            Text { anchors.centerIn:parent;text:root.current.icon;font.family:Theme.fontMono;font.pixelSize:24;color:root.modern?"white":Theme.accentIn(QsWindow.window) }
                        }
                        ColumnLayout { Layout.fillWidth:true;spacing:5
                            Text { Layout.fillWidth:true;text:root.current.label;color:Theme.textIn(QsWindow.window);font.family:root.forma&&root.design.headingFont?root.design.headingFont:Theme.fontIn(QsWindow.window);font.pixelSize:root.forma?root.design.headerSize:30;font.weight:root.modern?Font.DemiBold:root.forma?Font.Medium:Font.Bold }
                            Text { Layout.fillWidth:true;visible:!root.forma||root.design.showPageDescription;text:root.current.blurb;color:Theme.mutedIn(QsWindow.window);font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13;wrapMode:Text.WordWrap }
                        }
                    }
                    SettingsHero {
                        visible:!root.studio
                        Layout.fillWidth: true
                        icon: root.current.icon
                        title: root.current.label
                    }

                    TabStrip {
                        Layout.fillWidth: true
                        tabs: root.current.tabs
                        current: root.tab
                        onPicked: id => root.show(id)
                    }

                    Loader {
                        id: pageLoader

                        Layout.fillWidth: true
                        active:!root.overviewDesign || !root.atlasOverview
                        sourceComponent: root.current.page

                        onLoaded: {
                            pageLoader.item.tab=Qt.binding(()=>root.tab)
                            if("viewportTop" in pageLoader.item)pageLoader.item.viewportTop=Qt.binding(()=>page.contentY-pageLoader.y)
                            if("viewportHeight" in pageLoader.item)pageLoader.item.viewportHeight=Qt.binding(()=>page.height)
                            Qt.callLater(root.scrollToPart)
                            if(!pageExit.running)pageReveal.restart()
                        }


                    }
                    RowLayout {
                        visible:root.studio && (!root.forma||root.design.showFooter)
                        Layout.fillWidth:true; Layout.topMargin:8; Layout.bottomMargin:16
                        spacing:12
                        Repeater {
                            model:[-1,1]
                            Rectangle {
                                id:step
                                required property int modelData
                                readonly property int position:root.navigationOrder.findIndex(s=>s.id===root.section)+modelData
                                readonly property var entry:root.navigationOrder[Math.max(0,Math.min(root.navigationOrder.length-1,position))]
                                Layout.fillWidth:true;Layout.preferredWidth:1;implicitHeight:68;radius:16
                                enabled:position<root.navigationOrder.length
                                opacity:enabled?1:.35
                                color:stepMouse.containsMouse?root.design.fieldBackground:"transparent";border.width:1;border.color:root.design.borderColor || Theme.colourIn(QsWindow.window,"borderColor",Theme.border)
                                Column { anchors.left:parent.left;anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;anchors.margins:16;spacing:5
                                    Text { width:parent.width;text:step.modelData<0?Tr.t("PREVIOUS"):Tr.t("NEXT");horizontalAlignment:step.modelData<0?Text.AlignLeft:Text.AlignRight;font.family:Theme.fontMono;font.pixelSize:10;font.letterSpacing:1;color:Theme.mutedIn(QsWindow.window) }
                                    Text { width:parent.width;text:step.modelData<0?"← "+(step.position<0?Tr.t("Overview"):step.entry?.label || ""):(step.entry?.label || "")+" →";horizontalAlignment:step.modelData<0?Text.AlignLeft:Text.AlignRight;font.family:Theme.fontIn(QsWindow.window);font.pixelSize:13;font.weight:Font.Medium;color:Theme.textIn(QsWindow.window) }
                                }
                                MouseArea { id:stepMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:{if(step.position<0){root.atlasCategory="";root.atlasOverview=true}else root.go(step.entry.id, "")} }
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut { sequence:"Ctrl+K"; onActivated:root.modern ? referenceNavHost.item?.focusSearch() : root.studio ? studioNavHost.item?.focusSearch() : legacyNavHost.item ? legacyNavHost.item.focusSearch() : navSearch.forceActiveFocus() }
    Timer {
        id: initialPage
        interval: 1
        onTriggered: { if(root.studio)root.go(root.modern?"profile":root.forma?"settingsappearance":"profile",root.modern?"account":root.forma?"colours":"account");page.contentY=0 }
    }
    Component.onCompleted: initialPage.start()
    onStudioChanged:if(root.studio)initialPage.restart()
    onModernChanged:if(root.modern)initialPage.restart()
    function previewStats():var {return pageLoader.item?.previewStats ? pageLoader.item.previewStats() : {}}
    function scrollToPart():void {
        if (root.section === "profile" && root.tab === "region" && pageLoader.item)
            page.contentY=Math.max(0,Math.min(pageLoader.y+pageLoader.item.regionOffset-12,page.contentHeight-page.height))
    }
    Component { id:settingsAppearancePage; SettingsAppearancePage {} }
    Component { id:profilePage; ProfileSection {} }
    Component { id:librariesPage; LibrariesSection {} }
    Component {id:shellAnimationsPage;ShellAnimationsSection {}}
    Component { id:presetPage; PresetBrowser {kind:root.current.presetKind || "bar"} }
    Component{id:setupPresetsPage;SetupPresetsSettings {onPanelRequested:name=>root.panelRequested(name)}}
    Component{id:settingsDesignPage;SettingsDesignPage{}}
    Component { id:autoHidePage; AutoHideSection {} }
    Component { id: barPage;        BarIslandSection {} }
    Component { id: islandPage;     IslandSection {} }
    // Widgets are arranged on the desktop itself, behind this window.
    Component { id: widgetsPage;    WidgetsSection {
        onArranging: root.closed() } }
    Component { id: modulesPage;    ModulesSection {} }
    // Open the control centre before closing, while this panel still exists
    // to emit the request.
    Component { id: controlsPage;   ControlsSection {
        onArranging: {
            root.panelRequested("controls")
            root.closed()
        } } }
    Component { id: dockPage;       DockSection {} }
    Component { id: launcherPage;   LauncherSection {} }
    Component { id: appearancePage; AppearanceSection {
        onPanelRequested: name => root.panelRequested(name) } }
    Component { id: windowsPage;    WindowsSection {} }
    Component { id: inputPage;      InputSection {} }
    Component { id: monitorsPage;   MonitorsSection {} }
    Component { id: keysPage;       KeysSection {} }
    Component { id: sessionPage;    SessionSection {} }
    Component { id: systemPage;     SystemSection {} }
}
