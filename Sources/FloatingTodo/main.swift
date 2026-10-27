import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PanelController.shared.setup()

        // Control + Option + T, from any app.
        hotKey = HotKey(keyCode: kVK_ANSI_T, modifiers: controlKey | optionKey) {
            PanelController.shared.summon()
        }

        LoginItem.enableOnFirstLaunch()
    }

    // Opening the app again (Spotlight, Finder) while it's already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        PanelController.shared.summon()
        return false
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // no Dock icon, no menu bar
app.run()
