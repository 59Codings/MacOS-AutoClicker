
import Cocoa

class ClickEngine {
    private let settings: AppSettings
    private var isRunningInternal = false
    private let queue = DispatchQueue(label: "com.autoclicker.engine", qos: .userInteractive)
    
    private var clickCount = 0
    private let source = CGEventSource(stateID: .combinedSessionState)
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    func start() {
        print("ClickEngine: START requested")
        guard !isRunningInternal else { 
            print("ClickEngine: Already running")
            return 
        }
        isRunningInternal = true
        clickCount = 0
        
        DispatchQueue.main.async {
            self.settings.isRunning = true
        }
        
        queue.async {
            self.runLoop()
        }
    }
    
    func stop() {
        isRunningInternal = false
        DispatchQueue.main.async {
            self.settings.isRunning = false
        }
    }
    
    private func runLoop() {
        print("ClickEngine: Entering runLoop")
        
        let sourceLocal = source
        if sourceLocal == nil {
            print("ClickEngine: ERROR - Could not create CGEventSource")
        }
        
        while isRunningInternal {
            let cps = settings.isRandomCPS ? Double.random(in: 1.0...settings.cps) : settings.cps
            
            if settings.isClickLimitEnabled {
                if clickCount >= settings.clickLimit {
                    print("ClickEngine: Click limit reached (\(settings.clickLimit)). Stopping.")
                    stop()
                    break
                }
            }
            
            let mouseLoc = CGEvent(source: nil)?.location ?? .zero
            let downEvent = createMouseEvent(type: .down, location: mouseLoc, source: sourceLocal)
            let upEvent = createMouseEvent(type: .up, location: mouseLoc, source: sourceLocal)
            
            if settings.isUnlimited {
                downEvent?.post(tap: .cghidEventTap)
                upEvent?.post(tap: .cghidEventTap)
                clickCount += 1
                usleep(500)
            } else {
                let totalDelaySeconds = 1.0 / max(cps, 1.0)
                let dutyCycle = settings.clickDutyCycle / 100.0
                let holdDuration = totalDelaySeconds * dutyCycle
                let waitDuration = totalDelaySeconds - holdDuration
                
                if let de = downEvent, let ue = upEvent {
                    print("ClickEngine: Posting click \(clickCount)")
                    de.post(tap: .cghidEventTap)
                    if holdDuration > 0 {
                        usleep(UInt32(holdDuration * 1_000_000))
                    }
                    ue.post(tap: .cghidEventTap)
                    clickCount += 1
                }
                
                if waitDuration > 0 && isRunningInternal {
                    usleep(UInt32(waitDuration * 1_000_000))
                }
            }
        }
        print("ClickEngine: Exiting runLoop")
    }
    
    private func createMouseEvent(type: MouseEventType, location: CGPoint, source: CGEventSource?) -> CGEvent? {
        let (cgDown, cgUp, cgButton) = mouseButtonMapping(for: settings.mouseButton)
        let actualType = type == .down ? cgDown : cgUp
        let event = CGEvent(mouseEventSource: source, mouseType: actualType, mouseCursorPosition: location, mouseButton: cgButton)
        return event
    }
    
    private enum MouseEventType {
        case down
        case up
    }
    
    private func mouseButtonMapping(for button: MouseButton) -> (CGEventType, CGEventType, CGMouseButton) {
        switch button {
        case .left:
            return (.leftMouseDown, .leftMouseUp, .left)
        case .middle:
            return (.otherMouseDown, .otherMouseUp, .center)
        case .right:
            return (.rightMouseDown, .rightMouseUp, .right)
        }
    }
}
