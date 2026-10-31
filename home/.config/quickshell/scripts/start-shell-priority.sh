#!/usr/bin/env bash
# Apply the compositor cursor before the shell can map its first surface.
. "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/cursor-session-env.sh"
if command -v hyprctl >/dev/null 2>&1; then
    timeout 2 hyprctl setcursor "$XCURSOR_THEME" "$XCURSOR_SIZE" >/dev/null 2>&1 || true
fi
# Publish this compositor's display to D-Bus services, then retry the portal
# if it was activated too early. Keep this parallel to shell startup.
(
    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        timeout 2 dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE >/dev/null 2>&1 || true
    fi
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user reset-failed xdg-desktop-portal-hyprland.service >/dev/null 2>&1 || true
        systemctl --user start --no-block xdg-desktop-portal-hyprland.service >/dev/null 2>&1 || true
    fi
) &
export IMPASTO_SESSION_BOOT=1
scope_name="impasto-quickshell-$$"
if command -v systemd-run >/dev/null 2>&1; then
    if systemd-run --user --scope --quiet --collect --unit="$scope_name" --slice=app.slice \
        -p CPUWeight=1000 -p IOWeight=1000 qs -d -n; then
        systemd-run --user --quiet --collect --on-active=8s --unit="$scope_name-normal-priority" \
            /usr/bin/systemctl --user set-property --runtime "$scope_name.scope" CPUWeight=100 IOWeight=100
        exit 0
    fi
fi
exec qs -d -n
