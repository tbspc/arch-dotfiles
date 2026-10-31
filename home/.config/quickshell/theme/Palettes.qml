// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   P A L E T T E S                                                        │
// │   curated colour schemes · single source of truth                        │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQuick

// Curated palettes. This is the only place a palette is described: the
// customizer reads its label and swatches from here, and ThemeService reads
// the tokens from the same entry, so the two can never disagree.
QtObject {
    id: root

    readonly property var list: [
        {
            id: "catppuccin_mocha",
            name: "Catppuccin Mocha",
            badge: "Dark Pastel",
            swatches: ["#89b4fa", "#f5c2e7", "#a6e3a1", "#fab387"],
            colors: {
                background: "#1e1e2e", surface: "#181825", surfaceHover: "#313244",
                border: "#45475a", text: "#cdd6f4", textMuted: "#a6adc8",
                accent: "#89b4fa", accentHover: "#b4befe", accentText: "#11111b",
                red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af", blue: "#89b4fa"
            }
        },
        {
            id: "catppuccin_latte",
            name: "Catppuccin Latte",
            badge: "Light Clean",
            swatches: ["#1e66f5", "#8839ef", "#40a02b", "#ea76cb"],
            colors: {
                background: "#eff1f5", surface: "#e6e9ef", surfaceHover: "#ccd0da",
                border: "#bcc0cc", text: "#4c4f69", textMuted: "#6c6f85",
                accent: "#1e66f5", accentHover: "#04a5e5", accentText: "#eff1f5",
                red: "#d20f39", green: "#40a02b", yellow: "#df8e1d", blue: "#1e66f5"
            }
        },
        {
            id: "tokyo_night",
            wallpaper: "/home/tbs/.local/share/wallpapers/0346.jpg",
            name: "Tokyo Night",
            badge: "Cyber City",
            swatches: ["#7aa2f7", "#bb9af7", "#9ece6a", "#f7768e"],
            colors: {
                background: "#1a1b26", surface: "#16161e", surfaceHover: "#24283b",
                border: "#292e42", text: "#c0caf5", textMuted: "#7982a9",
                accent: "#7aa2f7", accentHover: "#bb9af7", accentText: "#15161e",
                red: "#f7768e", green: "#9ece6a", yellow: "#e0af68", blue: "#7aa2f7"
            }
        },
        {
            id: "gruvbox_dark",
            name: "Gruvbox Dark",
            badge: "Warm Retro",
            swatches: ["#d79921", "#83a598", "#b8bb26", "#fb4934"],
            colors: {
                background: "#282828", surface: "#1d2021", surfaceHover: "#3c3836",
                border: "#504945", text: "#ebdbb2", textMuted: "#a89984",
                accent: "#d79921", accentHover: "#fabd2f", accentText: "#282828",
                red: "#fb4934", green: "#b8bb26", yellow: "#fabd2f", blue: "#83a598"
            }
        },
        {
            id: "nord",
            name: "Nord",
            badge: "Arctic Frost",
            swatches: ["#88c0d0", "#81a1c1", "#a3be8c", "#bf616a"],
            colors: {
                background: "#2e3440", surface: "#242933", surfaceHover: "#3b4252",
                border: "#434c5e", text: "#eceff4", textMuted: "#d8dee9",
                accent: "#88c0d0", accentHover: "#81a1c1", accentText: "#2e3440",
                red: "#bf616a", green: "#a3be8c", yellow: "#ebcb8b", blue: "#81a1c1"
            }
        },
        {
            id: "rose_pine",
            name: "Rosé Pine",
            badge: "Soho Dusk",
            swatches: ["#ebbcba", "#f6c177", "#31748f", "#eb6f92"],
            colors: {
                background: "#191724", surface: "#1f1d2e", surfaceHover: "#26233a",
                border: "#403d52", text: "#e0def4", textMuted: "#908caa",
                accent: "#ebbcba", accentHover: "#f6c177", accentText: "#191724",
                red: "#eb6f92", green: "#31748f", yellow: "#f6c177", blue: "#9ccfd8"
            }
        },
        {
            id: "cyberpunk",
            name: "Cyberpunk",
            badge: "Neon Synth",
            swatches: ["#ff007f", "#00e5ff", "#ffea00", "#00e676"],
            colors: {
                background: "#0d0f18", surface: "#141726", surfaceHover: "#21253b",
                border: "#ff007f", text: "#e0f7fa", textMuted: "#00e5ff",
                accent: "#ff007f", accentHover: "#00e5ff", accentText: "#ffffff",
                red: "#ff1744", green: "#00e676", yellow: "#ffea00", blue: "#00e5ff"
            }
        },
        {
            id: "bauhaus",
            name: "Bauhaus",
            badge: "Modernist",
            swatches: ["#e52521", "#2b82d9", "#f5a623", "#f5f5f5"],
            colors: {
                background: "#1a1a1a", surface: "#242424", surfaceHover: "#333333",
                border: "#444444", text: "#f5f5f5", textMuted: "#999999",
                accent: "#e52521", accentHover: "#f5a623", accentText: "#ffffff",
                red: "#e52521", green: "#2b82d9", yellow: "#f5a623", blue: "#2b82d9"
            }
        },
        {
            id: "crimson",
            name: "Crimson Moon",
            badge: "Vampiric",
            swatches: ["#e63946", "#ff4d6d", "#ad8394", "#f7e1ea"],
            colors: {
                background: "#120a0d", surface: "#1c1015", surfaceHover: "#2d1822",
                border: "#4a2133", text: "#f7e1ea", textMuted: "#ad8394",
                accent: "#e63946", accentHover: "#ff4d6d", accentText: "#ffffff",
                red: "#e63946", green: "#52b788", yellow: "#ee9b00", blue: "#a2d2ff"
            }
        }
,
        {"id": "noir", "name": "Noir / Monochrome", "badge": "Quiet Monochrome", "swatches": ["#d4d4d4", "#a4b8d4", "#a4c6a4", "#d6c49a"], "colors": {"background": "#101012", "surface": "#09090b", "surfaceHover": "#202023", "border": "#36363b", "text": "#e6e6e6", "textMuted": "#a0a0a8", "accent": "#d4d4d4", "accentHover": "#ffffff", "accentText": "#101012", "red": "#dd8888", "green": "#a4c6a4", "yellow": "#d6c49a", "blue": "#a4b8d4"}, "source": "Original monochrome palette"},
        {"id": "kanagawa_wave", "name": "Kanagawa Wave", "badge": "Ink & Cream", "swatches": ["#7e9cd8", "#7e9cd8", "#98bb6c", "#e6c384"], "colors": {"background": "#1f1f28", "surface": "#16161d", "surfaceHover": "#2a2a37", "border": "#54546d", "text": "#dcd7ba", "textMuted": "#9a9a8f", "accent": "#7e9cd8", "accentHover": "#7fb4ca", "accentText": "#16161d", "red": "#c34043", "green": "#98bb6c", "yellow": "#e6c384", "blue": "#7e9cd8"}, "source": "https://github.com/rebelot/kanagawa.nvim"},
        {"id": "rose_pine_moon", "name": "Rosé Pine Moon", "badge": "Moonlit Rose", "swatches": ["#c4a7e7", "#9ccfd8", "#3e8fb0", "#f6c177"], "colors": {"background": "#232136", "surface": "#2a273f", "surfaceHover": "#393552", "border": "#44415a", "text": "#e0def4", "textMuted": "#908caa", "accent": "#c4a7e7", "accentHover": "#ea9a97", "accentText": "#232136", "red": "#eb6f92", "green": "#3e8fb0", "yellow": "#f6c177", "blue": "#9ccfd8"}, "source": "https://rosepinetheme.com/palette/"},
        {"id": "everforest_dark", "name": "Everforest Dark", "badge": "Soft Forest", "swatches": ["#a7c080", "#7fbbb3", "#a7c080", "#dbbc7f"], "colors": {"background": "#2d353b", "surface": "#232a2e", "surfaceHover": "#343f44", "border": "#475258", "text": "#d3c6aa", "textMuted": "#9da9a0", "accent": "#a7c080", "accentHover": "#83c092", "accentText": "#232a2e", "red": "#e67e80", "green": "#a7c080", "yellow": "#dbbc7f", "blue": "#7fbbb3"}, "source": "https://github.com/sainnhe/everforest"},
        {"id": "oxocarbon_dark", "name": "Oxocarbon Dark", "badge": "Carbon & Blue", "swatches": ["#78a9ff", "#78a9ff", "#42be65", "#f1c21b"], "colors": {"background": "#161616", "surface": "#262626", "surfaceHover": "#393939", "border": "#525252", "text": "#f2f4f8", "textMuted": "#a8a8a8", "accent": "#78a9ff", "accentHover": "#82cfff", "accentText": "#161616", "red": "#ee5396", "green": "#42be65", "yellow": "#f1c21b", "blue": "#78a9ff"}, "source": "https://github.com/nyoom-engineering/oxocarbon.nvim"},
        {"id": "dracula", "name": "Dracula", "badge": "Vivid Purple", "swatches": ["#bd93f9", "#8be9fd", "#50fa7b", "#f1fa8c"], "colors": {"background": "#282a36", "surface": "#21222c", "surfaceHover": "#44475a", "border": "#6272a4", "text": "#f8f8f2", "textMuted": "#a5abc6", "accent": "#bd93f9", "accentHover": "#ff79c6", "accentText": "#21222c", "red": "#ff5555", "green": "#50fa7b", "yellow": "#f1fa8c", "blue": "#8be9fd"}, "source": "https://draculatheme.com/contribute"},
        {"id": "material_ocean", "name": "Material Ocean", "badge": "Deep Ocean", "swatches": ["#81a1c1", "#81a1c1", "#a3be8c", "#ebcb8b"], "colors": {"background": "#0f111a", "surface": "#090b10", "surfaceHover": "#1b2130", "border": "#3b4252", "text": "#e5e9f0", "textMuted": "#a3adbd", "accent": "#81a1c1", "accentHover": "#88c0d0", "accentText": "#090b10", "red": "#bf616a", "green": "#a3be8c", "yellow": "#ebcb8b", "blue": "#81a1c1"}, "source": "https://github.com/material-ocean/Material-Ocean"},
        {"id": "osaka_jade", "name": "Osaka Jade", "badge": "Jade & Parchment", "swatches": ["#509475", "#509475", "#549e6a", "#e5c736"], "colors": {"background": "#111c18", "surface": "#0c1512", "surfaceHover": "#23372b", "border": "#32473b", "text": "#c1c497", "textMuted": "#81b8a8", "accent": "#509475", "accentHover": "#75bbb3", "accentText": "#090f0d", "red": "#ff5345", "green": "#549e6a", "yellow": "#e5c736", "blue": "#509475"}, "source": "https://github.com/omacom/omarchy-osaka-jade-theme"},
        {"id": "ayu_mirage", "name": "Ayu Mirage", "badge": "Amber Dusk", "swatches": ["#ffcc66", "#73d0ff", "#d5ff80", "#ffd173"], "colors": {"background": "#242936", "surface": "#1f2430", "surfaceHover": "#2d3443", "border": "#404957", "text": "#cccac2", "textMuted": "#8a9199", "accent": "#ffcc66", "accentHover": "#ffd580", "accentText": "#1f2430", "red": "#f28779", "green": "#d5ff80", "yellow": "#ffd173", "blue": "#73d0ff"}, "source": "https://github.com/ayu-theme/ayu-colors"},
        {"id": "monokai_pro", "name": "Monokai Pro", "badge": "Charcoal & Gold", "swatches": ["#ffd866", "#78dce8", "#a9dc76", "#ffd866"], "colors": {"background": "#2d2a2e", "surface": "#221f22", "surfaceHover": "#403e41", "border": "#5b595c", "text": "#fcfcfa", "textMuted": "#b0adae", "accent": "#ffd866", "accentHover": "#fc9867", "accentText": "#221f22", "red": "#ff6188", "green": "#a9dc76", "yellow": "#ffd866", "blue": "#78dce8"}, "source": "https://monokai.pro/"},
        {"id": "vantablack", "name": "Vantablack", "badge": "Black & Silver", "swatches": ["#b8b8b8", "#9fb6cc", "#9cc49c", "#d4c38a"], "colors": {"background": "#000000", "surface": "#080808", "surfaceHover": "#141414", "border": "#303030", "text": "#f5f5f5", "textMuted": "#999999", "accent": "#b8b8b8", "accentHover": "#e6e6e6", "accentText": "#000000", "red": "#e68181", "green": "#9cc49c", "yellow": "#d4c38a", "blue": "#9fb6cc"}, "source": "Original black and silver palette"},
        {"id": "miasma", "name": "Miasma", "badge": "Moss & Earth", "swatches": ["#78824b", "#8a9b65", "#5f875f", "#c9a554"], "colors": {"background": "#222222", "surface": "#1c1c1a", "surfaceHover": "#30312a", "border": "#4a4c3c", "text": "#c2c2b0", "textMuted": "#a0a08c", "accent": "#78824b", "accentHover": "#c9a554", "accentText": "#181a13", "red": "#b08866", "green": "#5f875f", "yellow": "#c9a554", "blue": "#8a9b65"}, "source": "https://github.com/xero/miasma.nvim"}
,
        {"id": "one_dark", "name": "One Dark", "badge": "Slate & Sapphire", "swatches": ["#61afef", "#c678dd", "#98c379", "#e5c07b"], "colors": {"background": "#282c34", "surface": "#21252b", "surfaceHover": "#353b45", "border": "#4b5263", "text": "#abb2bf", "textMuted": "#939baa", "accent": "#61afef", "accentHover": "#c678dd", "accentText": "#21252b", "red": "#e06c75", "green": "#98c379", "yellow": "#e5c07b", "blue": "#61afef"}, "source": "https://github.com/atom/one-dark-syntax"},
        {"id": "solarized_dark", "name": "Solarized Dark", "badge": "Ink & Copper", "swatches": ["#268bd2", "#2aa198", "#859900", "#b58900"], "colors": {"background": "#002b36", "surface": "#073642", "surfaceHover": "#0c4652", "border": "#586e75", "text": "#93a1a1", "textMuted": "#7b9296", "accent": "#268bd2", "accentHover": "#2aa198", "accentText": "#fdf6e3", "red": "#dc322f", "green": "#859900", "yellow": "#b58900", "blue": "#268bd2"}, "source": "https://ethanschoonover.com/solarized/"},
        {"id": "night_owl", "name": "Night Owl", "badge": "Midnight & Lavender", "swatches": ["#82aaff", "#c792ea", "#addb67", "#ecc48d"], "colors": {"background": "#011627", "surface": "#071d2b", "surfaceHover": "#172f45", "border": "#2a4a62", "text": "#d6deeb", "textMuted": "#7e91a3", "accent": "#82aaff", "accentHover": "#c792ea", "accentText": "#011627", "red": "#ef5350", "green": "#addb67", "yellow": "#ecc48d", "blue": "#82aaff"}, "source": "https://github.com/sdras/night-owl-vscode-theme"},
        {"id": "everblush", "name": "Everblush", "badge": "Charcoal & Mint", "swatches": ["#8ccf7e", "#6cbfbf", "#8ccf7e", "#e5c76b"], "colors": {"background": "#141b1e", "surface": "#1b2225", "surfaceHover": "#2b353a", "border": "#3b484d", "text": "#dadada", "textMuted": "#9aa5a5", "accent": "#8ccf7e", "accentHover": "#6cbfbf", "accentText": "#141b1e", "red": "#e57474", "green": "#8ccf7e", "yellow": "#e5c76b", "blue": "#67b0e8"}, "source": "https://github.com/Everblush/everblush"},
        {"id": "oceanic_next", "name": "Oceanic Next", "badge": "Ocean Teal", "swatches": ["#5fb3b3", "#99c794", "#99c794", "#fac863"], "colors": {"background": "#1b2b34", "surface": "#16232b", "surfaceHover": "#29404b", "border": "#4f5b66", "text": "#cdd3de", "textMuted": "#a0a7b0", "accent": "#5fb3b3", "accentHover": "#99c794", "accentText": "#16232b", "red": "#ec5f67", "green": "#99c794", "yellow": "#fac863", "blue": "#6699cc"}, "source": "https://github.com/voronianski/oceanic-next-color-scheme"}
    ]

    function byId(paletteId: string): var {
        return root.list.find(palette => palette.id === paletteId) ?? null
    }
}
