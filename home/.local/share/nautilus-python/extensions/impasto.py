# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   I M P A S T O                                                          │
# │   the file manager's right-click menu · terminal, editor, wallpaper      │
# │                                                                          │
# │   github.com/andreumassanet/impasto                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

"""Right-click actions for Nautilus, each using a program from impasto.

Loaded by nautilus-python when Nautilus starts.
"""

import subprocess
import os
import gi
gi.require_version("Adw", "1")

from gi.repository import Adw, Gdk, Gio, GLib, GObject, Gtk, Nautilus


def run(*command):
    """Start a program detached from Nautilus."""
    try:
        subprocess.Popen(command, start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def copy(text):
    try:
        subprocess.run(["wl-copy"], input=text, text=True, timeout=5)
    except (OSError, subprocess.SubprocessError):
        pass


def item(name, label, icon, action):
    entry = Nautilus.MenuItem(name=f"Impasto::{name}", label=label, icon=icon)
    entry.connect("activate", lambda _entry: action())
    return entry


def folder_items(path):
    return [
        item("terminal", "Open Terminal Here", "utilities-terminal",
             lambda: run("kitty", "--working-directory", path)),
        item("yazi", "Open yazi Here", "folder-open",
             lambda: run("kitty", "--working-directory", path, "yazi")),
    ]


class ImpastoMenu(GObject.GObject, Nautilus.MenuProvider):

    def __init__(self):
        super().__init__()
        # GTK loads ~/.config/gtk-4.0/gtk.css at startup and does not watch it.
        # Keep an additional provider in Nautilus and reload it when Impasto
        # rewrites the palette, so its open windows update in place.
        config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
        data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
        css_path = os.path.join(config_home, "gtk-4.0", "gtk.css")
        self._gtk_css = Gio.File.new_for_path(css_path)
        state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
        self._nautilus_css = Gio.File.new_for_path(os.path.join(state_home, "quickshell", "nautilus-glass.css"))
        self._css_provider = Gtk.CssProvider()
        display = Gdk.Display.get_default()
        if display is not None:
            Gtk.StyleContext.add_provider_for_display(
                display, self._css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)
            # This preference is local to Files, leaving other applications alone.
            settings = Gtk.Settings.get_for_display(display)
            layout = settings.get_property("gtk-decoration-layout") or ":close"
            settings.set_property("gtk-decoration-layout", ":".join(
                ",".join(button for button in side.split(",") if button != "close")
                for side in layout.split(":")))
            self._reload_css()
            self._css_monitors = []
            for file in (self._gtk_css, self._nautilus_css):
                monitor = file.get_parent().monitor_directory(Gio.FileMonitorFlags.WATCH_MOVES, None)
                monitor.connect("changed", self._css_changed)
                self._css_monitors.append(monitor)

            # Impasto rebuilds its icon theme by swapping the directory, so
            # watch its parent rather than the theme directory itself.
            icons_path = os.path.join(data_home, "icons")
            self._icons_directory = Gio.File.new_for_path(icons_path)
            try:
                self._icons_monitor = self._icons_directory.monitor_directory(
                    Gio.FileMonitorFlags.WATCH_MOVES, None)
                self._icons_monitor.connect("changed", self._icons_changed)
            except GLib.Error:
                self._icons_monitor = None

    def _css_changed(self, _monitor, file, other_file, _event):
        names = [item.get_basename() for item in (file, other_file) if item]
        if not any(name in ("gtk.css", "nautilus-glass.css") for name in names):
            return
        if not getattr(self, "_css_reload_timeout", 0):
            self._css_reload_timeout = GLib.idle_add(self._reload_css)

    def _reload_css(self):
        self._css_reload_timeout = 0
        try:
            base = self._gtk_css.load_contents(None)[1].decode("utf-8")
            try:
                glass = self._nautilus_css.load_contents(None)[1].decode("utf-8")
            except GLib.Error:
                glass = ""
            # Match libadwaita's widget variants to the selected palette.
            import re
            match = re.search(r"@define-color window_bg_color (#[0-9a-fA-F]{6});", base)
            if match:
                value = match[1]
                rgb = [int(value[i:i+2], 16)/255 for i in (1,3,5)]
                dark = sum(v*w for v,w in zip(rgb, (.2126,.7152,.0722))) < .5
                Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK if dark else Adw.ColorScheme.FORCE_LIGHT)
            self._css_provider.load_from_string(base + "\n" + glass)
        except GLib.Error:
            pass
        return GLib.SOURCE_REMOVE

    def _icons_changed(self, _monitor, file, other_file, _event):
        paths = [file.get_path() if file else "",
                 other_file.get_path() if other_file else ""]
        if not any(os.path.basename(path) in ("impasto", "impasto.building", "impasto-reference", "impasto-reference.building")
                   for path in paths):
            return
        # The icon theme is built in a temporary directory and then renamed
        # into place. Wait until that swap is complete before refreshing GTK.
        if getattr(self, "_icon_refresh_timeout", 0):
            GLib.source_remove(self._icon_refresh_timeout)
        self._icon_refresh_timeout = GLib.timeout_add(350, self._refresh_icons)

    def _refresh_icons(self):
        self._icon_refresh_timeout = 0
        display = Gdk.Display.get_default()
        if display is None:
            return GLib.SOURCE_REMOVE
        settings = Gtk.Settings.get_for_display(display)
        current = settings.get_property("gtk-icon-theme-name") or "impasto"
        temporary = "Papirus-Dark" if current != "Papirus-Dark" else "Adwaita"
        settings.set_property("gtk-icon-theme-name", temporary)
        self._icon_restore_timeout = GLib.timeout_add(
            80, self._restore_icon_theme, current)
        return GLib.SOURCE_REMOVE

    def _restore_icon_theme(self, theme_name):
        display = Gdk.Display.get_default()
        if display is not None:
            Gtk.Settings.get_for_display(display).set_property(
                "gtk-icon-theme-name", theme_name)
        self._icon_restore_timeout = 0
        return GLib.SOURCE_REMOVE

    def get_file_items(self, files):
        paths = [f.get_location().get_path() for f in files]
        if not paths or None in paths:
            return []

        items = []
        if len(files) == 1 and files[0].is_directory():
            items += folder_items(paths[0])
        items.append(item("editor", "Open in the Editor", "accessories-text-editor",
                          lambda: run("codium", *paths)))
        if len(files) == 1 and files[0].get_mime_type().startswith(("image/", "video/")):
            items.append(item("wallpaper", "Set as Wallpaper",
                              "preferences-desktop-wallpaper",
                              lambda: run("qs", "ipc", "call", "wallpaper", "set", paths[0])))
        items.append(item("copy-path", "Copy Path", "edit-copy",
                          lambda: copy("\n".join(paths))))
        return items

    def get_background_items(self, folder):
        path = folder.get_location().get_path()
        if path is None:
            return []
        return folder_items(path) + [
            item("editor-here", "Open in the Editor", "accessories-text-editor",
                 lambda: run("codium", path)),
        ]
