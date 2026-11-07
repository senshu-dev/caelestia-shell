//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Scheme
import qs.services
import qs.modules.areapicker
import qs.modules.background
import qs.modules.drawers
import qs.modules.lock
import qs.daemons

ShellRoot {
    id: root

    settings.watchFiles: true

    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }

    FontLoader {
        source: Quickshell.shellPath("assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    IpcHandler {
        function set(path: string): void {
            Wallpapers.setWallpaper(path);
        }

        function assign(wsName: string, path: string): void {
            Wallpapers.assignToWorkspace(wsName, path);
        }

        function clear(wsName: string): void {
            Wallpapers.clearWorkspace(wsName);
        }

        function clearAll(): void {
            Wallpapers.clearWorkspaces();
        }

        function get(wsName: string): string {
            return Wallpapers.wallpaperForWorkspace(wsName) || Wallpapers.current;
        }

        target: "wallpaper"
    }

    // Modules
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    // Daemons
    Shortcuts {}
    BatteryMonitor {}
    BlurController {}
    GameMode {}
    IdleInhibit {}
    IdleMonitors {
        lock: lock
    }
}
