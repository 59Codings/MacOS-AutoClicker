
import Foundation

struct SettingsPayload: Codable {
    var hotkey: Hotkey
    var activationMode: ActivationMode
    var cps: Double
    var isUnlimited: Bool
    var isRandomCPS: Bool
    var clickDutyCycle: Double
    var mouseButton: MouseButton
    var isClickLimitEnabled: Bool
    var clickLimit: Int
    var language: String
    var isStartWithMacOS: Bool
}

class SettingsStorage {
    static let shared = SettingsStorage()
    
    private let fileManager = FileManager.default
    
    private var fileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("AutoClicker")
        
        if !fileManager.fileExists(atPath: appDir.path) {
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        return appDir.appendingPathComponent("config.plist")
    }
    
    func save(settings: AppSettings) {
        let payload = SettingsPayload(
            hotkey: settings.hotkey,
            activationMode: settings.activationMode,
            cps: settings.cps,
            isUnlimited: settings.isUnlimited,
            isRandomCPS: settings.isRandomCPS,
            clickDutyCycle: settings.clickDutyCycle,
            mouseButton: settings.mouseButton,
            isClickLimitEnabled: settings.isClickLimitEnabled,
            clickLimit: settings.clickLimit,
            language: settings.language,
            isStartWithMacOS: settings.isStartWithMacOS
        )
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(payload)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func load(into settings: AppSettings) {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        
        let decoder = PropertyListDecoder()
        if let payload = try? decoder.decode(SettingsPayload.self, from: data) {
            settings.hotkey = payload.hotkey
            settings.activationMode = payload.activationMode
            settings.cps = payload.cps
            settings.isUnlimited = payload.isUnlimited
            settings.isRandomCPS = payload.isRandomCPS
            settings.clickDutyCycle = payload.clickDutyCycle
            settings.mouseButton = payload.mouseButton
            settings.isClickLimitEnabled = payload.isClickLimitEnabled
            settings.clickLimit = payload.clickLimit
            settings.language = payload.language
            settings.isStartWithMacOS = payload.isStartWithMacOS
            return
        }
        
        print("SettingsStorage: Full decode failed, attempting field-by-field recovery")
        guard let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            print("SettingsStorage: Could not read settings file as dictionary – starting fresh")
            return
        }
        
        if let raw = dict["cps"] as? Double { settings.cps = raw }
        if let raw = dict["clickDutyCycle"] as? Double { settings.clickDutyCycle = raw }
        if let raw = dict["isUnlimited"] as? Bool { settings.isUnlimited = raw }
        if let raw = dict["isRandomCPS"] as? Bool { settings.isRandomCPS = raw }
        if let raw = dict["isClickLimitEnabled"] as? Bool { settings.isClickLimitEnabled = raw }
        if let raw = dict["clickLimit"] as? Int { settings.clickLimit = raw }
        if let raw = dict["language"] as? String { settings.language = raw }
        if let raw = dict["isStartWithMacOS"] as? Bool { settings.isStartWithMacOS = raw }
        if let raw = dict["activationMode"] as? String,
           let mode = ActivationMode(rawValue: raw) { settings.activationMode = mode }
        if let raw = dict["mouseButton"] as? String,
           let btn = MouseButton(rawValue: raw) { settings.mouseButton = btn }
    }
}
