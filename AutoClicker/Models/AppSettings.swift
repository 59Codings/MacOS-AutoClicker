
import SwiftUI
import Combine

enum ActivationMode: String, Codable {
    case toggle
    case hold
}

enum MouseButton: String, Codable {
    case left
    case middle
    case right
}

enum HotkeyType: String, Codable {
    case keyboard
    case mouse
}

struct Hotkey: Codable, Equatable {
    var type: HotkeyType
    var keyCode: UInt16? // keyboard
    var mouseButton: Int? // mouse (e.g., 3, 4, 5)
    var displayString: String
    
    static let defaultHotkey = Hotkey(type: .keyboard, keyCode: 122, mouseButton: nil, displayString: "F1") // 122 is F1
}

@Observable
class AppSettings {
    var hotkey: Hotkey = Hotkey.defaultHotkey {
        didSet { save() }
    }
    
    var activationMode: ActivationMode = .toggle {
        didSet { save() }
    }
    
    var cps: Double = 200.0 {
        didSet { save() }
    }
    
    var isUnlimited: Bool = false {
        didSet { save() }
    }
    
    var isRandomCPS: Bool = false {
        didSet { save() }
    }
    
    var clickDutyCycle: Double = 50.0 {
        didSet { save() }
    }
    
    var mouseButton: MouseButton = .left {
        didSet { save() }
    }
    
    var isClickLimitEnabled: Bool = false {
        didSet { save() }
    }
    
    var clickLimit: Int = 1000 {
        didSet { save() }
    }
    
    var language: String = LanguageManager.availableLanguages.first?.id ?? "en" {
        didSet { save() }
    }
    
    var isStartWithMacOS: Bool = false {
        didSet { save() }
    }
    
    var isAccessibilityGranted: Bool = false
    
    var isRunning: Bool = false
    
    private var isInitializing = true
    
    init() {
        SettingsStorage.shared.load(into: self)
        
        let validLanguageIds = LanguageManager.availableLanguages.map { $0.id }
        if !validLanguageIds.contains(self.language) {
            self.language = validLanguageIds.first ?? "en"
        }
        
        if self.hotkey.type == .mouse && self.hotkey.mouseButton == 0 {
            self.hotkey = Hotkey.defaultHotkey
        }
        
        self.isAccessibilityGranted = AccessibilityManager.isTrusted
        
        isInitializing = false
    }
    
    func resetToDefaults() {
        let isInitBackup = isInitializing
        isInitializing = true
        
        hotkey = Hotkey.defaultHotkey
        activationMode = .toggle
        cps = 200.0
        clickDutyCycle = 50.0
        mouseButton = .left
        isClickLimitEnabled = false
        clickLimit = 1000
        isUnlimited = false
        isRandomCPS = false
        isStartWithMacOS = false
        language = LanguageManager.availableLanguages.first?.id ?? "en"
        
        isInitializing = isInitBackup
        save()
    }
    
    func save() {
        if isInitializing { return }
        SettingsStorage.shared.save(settings: self)
    }
}
