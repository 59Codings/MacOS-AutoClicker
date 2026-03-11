
import Cocoa

class HotkeyManager {
    private let settings: AppSettings
    private let engine: ClickEngine
    
    private var isListeningForNewHotkey = false
    private var hotkeyChangeCallback: ((Hotkey) -> Void)?
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isStarted = false
    
    private var isHotkeyDown = false
    
    init(settings: AppSettings, engine: ClickEngine) {
        self.settings = settings
        self.engine = engine
    }
    
    func start() {
        guard !isStarted else { return }
        
        setupMonitors()
        isStarted = true
        print("HotkeyManager: Started")
    }
    
    func stop() {
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
        isStarted = false
        print("HotkeyManager: Stopped")
    }
    
    func listenForNextHotkey(completion: @escaping (Hotkey) -> Void) {
        isListeningForNewHotkey = true
        hotkeyChangeCallback = completion
    }
    
    private func setupMonitors() {
        if globalMonitor == nil && AccessibilityManager.isTrusted {
            let globalMask: NSEvent.EventTypeMask = [
                .keyDown, .keyUp,
                .leftMouseDown, .leftMouseUp,
                .rightMouseDown, .rightMouseUp,
                .otherMouseDown, .otherMouseUp
            ]
            
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: globalMask) { [weak self] event in
                _ = self?.handleEvent(event)
            }
            print("HotkeyManager: Global monitor added (Trusted: YES)")
        } else if globalMonitor == nil {
            print("HotkeyManager: Skipping global monitor (Trusted: NO)")
        }
        
        if localMonitor == nil {
            let localMask: NSEvent.EventTypeMask = [.keyDown, .keyUp, .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp]
            
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: localMask) { [weak self] event in
                guard let self = self else { return event }
                
                if self.isListeningForNewHotkey {
                    if self.handleEvent(event) == true {
                        return nil
                    }
                    return event
                }
                
                if event.type == .leftMouseDown || event.type == .leftMouseUp {
                    return event
                }
                
                if self.handleEvent(event) == true {
                    return nil
                }
                
                return event
            }
        }
    }
    
    func refreshMonitors() {
        if globalMonitor == nil && AccessibilityManager.isTrusted {
            setupMonitors()
        }
    }
    
    private func handleEvent(_ event: NSEvent) -> Bool {
        if event.type == .keyDown || event.type == .keyUp {
            print("HotkeyManager: Key event: \(event.type) keyCode: \(event.keyCode)")
        } else {
            print("HotkeyManager: Mouse event: \(event.type)")
        }
        
        if isListeningForNewHotkey {
            let hotkey = parseEventForHotkeySelection(event)
            if let hotkey = hotkey {
                isListeningForNewHotkey = false
                hotkeyChangeCallback?(hotkey)
                hotkeyChangeCallback = nil
                return true
            }
            return false
        }
        
        let isMatch = isEventMatchingCurrentHotkey(event)
        if !isMatch {
            if settings.activationMode == .hold && isEventMatchingCurrentHotkeyUp(event) {
                if isHotkeyDown {
                    isHotkeyDown = false
                    engine.stop()
                }
            }
            return false
        }
        
        if isMatch {
            print("HotkeyManager: MATCH found for hotkey! (\(settings.hotkey.displayString))")
        }
        
        if settings.activationMode == .toggle {
            if isKeyDownEvent(event) {
                if settings.isRunning {
                    print("HotkeyManager: Stopping engine (toggle)")
                    engine.stop()
                } else {
                    print("HotkeyManager: Starting engine (toggle)")
                    engine.start()
                }
            }
        } else if settings.activationMode == .hold {
            if isKeyDownEvent(event) {
                if !isHotkeyDown {
                    print("HotkeyManager: Starting engine (hold)")
                    isHotkeyDown = true
                    engine.start()
                }
            }
        }
        
        return true
    }
    
    private func isKeyDownEvent(_ event: NSEvent) -> Bool {
        switch event.type {
        case .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown:
            return true
        default:
            return false
        }
    }
    
    private func isEventMatchingCurrentHotkey(_ event: NSEvent) -> Bool {
        if settings.hotkey.type == .keyboard {
            return (event.type == .keyDown || event.type == .keyUp) && event.keyCode == settings.hotkey.keyCode
        } else {
            switch event.type {
            case .leftMouseDown: return settings.hotkey.mouseButton == 0
            case .rightMouseDown: return settings.hotkey.mouseButton == 1
            case .otherMouseDown: return settings.hotkey.mouseButton == event.buttonNumber
            default: return false
            }
        }
    }
    
    private func isEventMatchingCurrentHotkeyUp(_ event: NSEvent) -> Bool {
        if settings.hotkey.type == .keyboard {
            return event.type == .keyUp && event.keyCode == settings.hotkey.keyCode
        } else {
            switch event.type {
            case .leftMouseUp: return settings.hotkey.mouseButton == 0
            case .rightMouseUp: return settings.hotkey.mouseButton == 1
            case .otherMouseUp: return settings.hotkey.mouseButton == event.buttonNumber
            default: return false
            }
        }
    }
    
    private func parseEventForHotkeySelection(_ event: NSEvent) -> Hotkey? {
        if event.type == .keyDown {
            print("HotkeyManager: Selection event characters: '\(event.characters ?? "nil")' ignoring modifiers: '\(event.charactersIgnoringModifiers ?? "nil")'")
            
            var display = stringForKeyCode(event.keyCode)
            
            if display == nil {
                if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                    display = chars.uppercased()
                    print("HotkeyManager: Using chars from event: \(display!)")
                } else {
                    print("HotkeyManager: Chars empty or nil, falling back to Key code")
                }
            } else {
                print("HotkeyManager: Using mapped string: \(display!)")
            }
            
            let finalDisplay = display ?? "Key \(event.keyCode)"
            print("HotkeyManager: Final Hotkey Display: '\(finalDisplay)'")
            return Hotkey(type: .keyboard, keyCode: event.keyCode, mouseButton: nil, displayString: finalDisplay)
        } else if let btnNum = extractMouseButton(from: event) {
            if btnNum == 0 { return nil }
            return Hotkey(type: .mouse, keyCode: nil, mouseButton: btnNum, displayString: "Mouse \(btnNum)")
        }
        return nil
    }
    
    private func extractMouseButton(from event: NSEvent) -> Int? {
        switch event.type {
        case .leftMouseDown: return 0
        case .rightMouseDown: return 1
        case .otherMouseDown: return event.buttonNumber
        default: return nil
        }
    }
    
    private func stringForKeyCode(_ keyCode: UInt16) -> String? {
        switch keyCode {
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 49: return "Space"
        case 53: return "Escape"
        case 36: return "Return"
        case 51: return "Delete"
        case 48: return "Tab"
        case 123: return "Left"
        case 124: return "Right"
        case 125: return "Down"
        case 126: return "Up"
        default: return nil
        }
    }
}
