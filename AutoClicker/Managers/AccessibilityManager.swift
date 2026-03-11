
import Cocoa

struct AccessibilityManager {
    static var isTrusted: Bool {
        return AXIsProcessTrusted()
    }

    static func refreshTrustStatus() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        return AXIsProcessTrustedWithOptions(options)
    }

    @discardableResult
    static func requestAccess() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        print("Accessibility Trust status requested with prompt. Currently: \(trusted)")
        return trusted
    }

    static func observeAccessibilityChanges(handler: @escaping (Bool) -> Void) -> NSObjectProtocol {
        return DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handler(AXIsProcessTrusted())
            }
        }
    }
}
