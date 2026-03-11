
import SwiftUI

@main
struct AutoClickerApp: App {
    @State private var settings = AppSettings()
    private var clickEngine: ClickEngine
    private var hotkeyManager: HotkeyManager
    @State private var accessibilityObserver: NSObjectProtocol?

    init() {
        let currentSettings = AppSettings()
        _settings = State(initialValue: currentSettings)

        let engine = ClickEngine(settings: currentSettings)
        self.clickEngine = engine
        self.hotkeyManager = HotkeyManager(settings: currentSettings, engine: engine)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings, hotkeyManager: hotkeyManager, clickEngine: clickEngine)
                .onAppear {
                    hotkeyManager.start()

                    if !AccessibilityManager.isTrusted {
                        AccessibilityManager.requestAccess()
                    }

                    let observer = AccessibilityManager.observeAccessibilityChanges { trusted in
                        settings.isAccessibilityGranted = trusted
                        if trusted {
                            hotkeyManager.refreshMonitors()
                        }
                    }
                    accessibilityObserver = observer
                }
        }
        .windowResizability(.contentSize)
    }
}
