import ServiceManagement

/// Starts the app automatically when you log in to your Mac.
/// Shows up in System Settings → General → Login Items.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Floating Todo: couldn't update login item: \(error)")
        }
    }

    /// Turn it on the first time the app runs. After that, respect whatever
    /// the user chose in the right-click menu.
    static func enableOnFirstLaunch() {
        let key = "didSetUpLoginItem"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        set(true)
    }
}
