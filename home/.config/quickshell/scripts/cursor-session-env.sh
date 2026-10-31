#!/bin/sh
impasto_cursor_env="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/20-impasto-cursor.conf"
if [ -r "$impasto_cursor_env" ]; then
    while IFS='=' read -r impasto_cursor_key impasto_cursor_value; do
        case "$impasto_cursor_key" in
            XCURSOR_THEME|HYPRCURSOR_THEME|XCURSOR_SIZE|HYPRCURSOR_SIZE)
                case "$impasto_cursor_value" in
                    ''|*[!a-zA-Z0-9_.-]*) continue ;;
                esac
                export "$impasto_cursor_key=$impasto_cursor_value"
                ;;
        esac
    done < "$impasto_cursor_env"
fi
: "${XCURSOR_THEME:=macos-tahoe-cursor}"
: "${HYPRCURSOR_THEME:=$XCURSOR_THEME}"
: "${XCURSOR_SIZE:=24}"
: "${HYPRCURSOR_SIZE:=$XCURSOR_SIZE}"
export XCURSOR_THEME HYPRCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_SIZE
unset impasto_cursor_env impasto_cursor_key impasto_cursor_value
