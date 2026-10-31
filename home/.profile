# Cursor environment must exist before SDDM starts Hyprland (including fish).
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/cursor-session-env.sh" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/cursor-session-env.sh"
fi
