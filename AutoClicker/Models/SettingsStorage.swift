
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
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = PropertyListDecoder()
            let payload = try decoder.decode(SettingsPayload.self, from: data)
            
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
        } catch {
            print("Failed to load settings from \(fileURL): \(error)")
        }
    }
}
