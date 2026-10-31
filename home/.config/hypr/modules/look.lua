-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │                                                                          │
-- │   L O O K                                                                │
-- │   appearance · gaps, borders, blur, layouts                              │
-- │                                                                          │
-- │   github.com/andreumassanet/impasto                                      │
-- │                                                                          │
-- ╰──────────────────────────────────────────────────────────────────────────╯

-- ── GENERAL ─────────────────────────────────────────────────────────────────

hl.config({
    general = {
        -- gaps_out matches the bar's edge margin (Bar.edgeMargin). gaps_in
        -- applies to each side, so 7 gives 14 px between windows.
        gaps_in  = 7,
        gaps_out = 18,

        -- No borders, hence no col.*_border: the gaps and rounding separate
        -- windows.
        border_size = 0,

        -- Snap floating windows to the same gaps tiled ones get.
        snap = {
            enabled        = true,
            window_gap     = 14,
            monitor_gap    = 18,
            border_overlap = false,
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },
})


-- ── DECORATION ──────────────────────────────────────────────────────────────

hl.config({
    decoration = {
        -- rounding_power 2 is a circular arc, like a QML Rectangle's corner.
        rounding       = 22,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Toggled from Settings → Appearance: CompositorService.applyShadow
        -- pushes it at startup and on `configreloaded`, using the values in
        -- Theme.qml (shared with the bar's capsules). Off without the shell.
        shadow = {
            enabled      = false,
            range        = 14,
            render_power = 3,
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
            xray              = true,
        },
    },
})


-- ── GLASS ───────────────────────────────────────────────────────────────────

-- hyprglass (built by `./setup plugins`): refracted blur behind windows. The
-- guard skips the block on the first parse, before the plugin is loaded.
--
-- Off without the shell; toggled from Settings → Appearance and pushed by
-- CompositorService like the shadow.
--
-- Tuned for kitty at 0.90 opacity, where the defaults flatten the background
-- into a wash: less blur, no dimming or tone mapping, a lighter tint and a
-- stronger edge. Only values that differ from the defaults are listed. Layers
-- stay off (the default).
if hl.plugin.hyprglass ~= nil then
    hl.plugin.hyprglass.config({
        enabled = false,

        blur_strength        = 0.7,    -- default 2.0

        -- Edge effects, all raised so the pane still reads at 0.90 opacity.
        refraction_strength  = 1.0,
        chromatic_aberration = 0.6,
        fresnel_strength     = 1.0,
        specular_strength    = 1.0,
        edge_thickness       = 0.10,

        -- Less magnification; it smears at this blur level.
        lens_distortion      = 0.3,

        -- Default tint at half alpha.
        tint_color           = 0x8899aa11,

        -- Tone mapping off: the dark preset dims and flattens an already
        -- dark wallpaper.
        dark = {
            brightness   = 1.0,
            contrast     = 1.0,
            saturation   = 0.9,
            adaptive_dim = 0.0,
        },
    })
end


-- ── LAYOUTS ─────────────────────────────────────────────────────────────────

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },

    -- No update news or donation popups.
    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

-- MacShell glass: register selectors during config load. Live strength/colour
-- values are controlled by Quickshell. An empty preset inherits live globals.
if hl.plugin.hyprglass ~= nil then
    local hg = hl.plugin.hyprglass
    hg.preset("impasto_tahoe", {})
    hg.preset("impasto_tahoe_bar", {})
    hg.preset("impasto_original", {blur_strength=0.7,blur_iterations=3,noise_strength=0.0,refraction_strength=1.0,refraction_spread=1.0,refraction_flow=0.0,lens_distortion=0.3,chromatic_aberration=0.6,saturation=-1.0,vibrancy=-1.0,brightness=-1.0,contrast=-1.0,adaptive_dim=-1.0,adaptive_boost=-1.0,self_sample=0.0,xray=0,fresnel_strength=1.0,fresnel_tint=0.0,fresnel_reflection=0.0,specular_strength=1.0,bevel_strength=0.0,bevel_size=6.0,edge_thickness_px=0.0,edge_height=0.0,tint_color=2291771921,glass_opacity=1.0,dark={blur_strength=-1.0,blur_iterations=-1,noise_strength=-1.0,refraction_strength=-1.0,refraction_spread=-1.0,refraction_flow=-1.0,lens_distortion=-1.0,chromatic_aberration=-1.0,saturation=0.9,vibrancy=0.15,brightness=1.0,contrast=1.0,adaptive_dim=0.0,adaptive_boost=0,self_sample=-1.0,xray=-1,fresnel_strength=-1.0,fresnel_tint=-1.0,fresnel_reflection=-1.0,specular_strength=-1.0,bevel_strength=-1.0,bevel_size=-1.0,edge_thickness_px=-1.0,edge_height=-1.0,tint_color=-1,glass_opacity=-1.0},light={blur_strength=-1.0,blur_iterations=-1,noise_strength=-1.0,refraction_strength=-1.0,refraction_spread=-1.0,refraction_flow=-1.0,lens_distortion=-1.0,chromatic_aberration=-1.0,saturation=0.85,vibrancy=0.12,brightness=1.12,contrast=0.92,adaptive_dim=0,adaptive_boost=0.4,self_sample=-1.0,xray=-1,fresnel_strength=-1.0,fresnel_tint=-1.0,fresnel_reflection=-1.0,specular_strength=-1.0,bevel_strength=-1.0,bevel_size=-1.0,edge_thickness_px=-1.0,edge_height=-1.0,tint_color=-1,glass_opacity=-1.0}})
    hg.config({ layers = { namespaces = "impasto-bar,impasto-dock" } })
    hg.layer("impasto-bar", { preset = "impasto_tahoe_bar", mask_threshold = 0.12, live_resample = true })
    hg.layer("impasto-dock", { preset = "impasto_tahoe_bar", mask_threshold = 0.12, live_resample = true })
end

-- Retain rule handles: live toggles must update the existing rules.
if hl.plugin.hyprglass ~= nil then
    _G.impastoMacGlassRules = {
        impasto_tahoe_windows_enable=hl.window_rule({name="impasto-tahoe-windows-enable",match={class=".*"},tag="+hyprglass_enabled"}),
        impasto_tahoe_windows_preset=hl.window_rule({name="impasto-tahoe-windows-preset",match={class=".*"},tag="+hyprglass_preset_impasto_tahoe"}),
        impasto_tahoe_terminal_enable=hl.window_rule({name="impasto-tahoe-terminal-enable",match={class="^(kitty)$"},tag="+hyprglass_enabled"}),
        impasto_tahoe_terminal_preset=hl.window_rule({name="impasto-tahoe-terminal-preset",match={class="^(kitty)$"},tag="+hyprglass_preset_impasto_tahoe"}),
        impasto_tahoe_shell_no_double=hl.window_rule({name="impasto-tahoe-shell-no-double",match={class="^(org.quickshell|quickshell)$"},tag="+hyprglass_disabled"}),
        impasto_tahoe_settings_enable=hl.window_rule({name="impasto-tahoe-settings-enable",match={class="^(org.quickshell|quickshell)$",title="^(Hyprland Settings)$"},tag="+hyprglass_enabled"}),
        impasto_tahoe_settings_preset=hl.window_rule({name="impasto-tahoe-settings-preset",match={class="^(org.quickshell|quickshell)$",title="^(Hyprland Settings)$"},tag="+hyprglass_preset_impasto_tahoe"})
    }
    for _, rule in pairs(_G.impastoMacGlassRules) do rule:set_enabled(false) end
end
