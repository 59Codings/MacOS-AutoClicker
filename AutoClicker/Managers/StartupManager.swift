
import ServiceManagement
import Foundation

class StartupManager {
    static func updateStartupStatus(isEnabled: Bool) {
        do {
            if isEnabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notRegistered { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to change startup status: \(error)")
        }
    }
}
